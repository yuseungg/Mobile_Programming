// 주인: C — firestore.rules 테스트 (Firestore 에뮬레이터 위에서 돈다)
// 실행: firestore_test/README.md
//
// 앱 저장소(lib/data/firestore/)가 실제로 하는 쓰기 모양 그대로 시험한다.

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  arrayUnion,
  collection,
  doc,
  getDoc,
  getDocs,
  increment,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;

const ME = 'alice';
const OTHER = 'bob';
const POEM = 'seosi';

// emulators:exec가 넣어 주는 주소를 쓴다 (없으면 firebase.json의 기본값)
const [emulatorHost, emulatorPort] =
  (process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080').split(':');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-yeobaek',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
      host: emulatorHost,
      port: Number(emulatorPort),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

// 실제 로그인 토큰처럼 이메일 클레임을 붙인다 (가입 규칙이 gmail.com을 확인한다)
const dbOf = (uid, email = `${uid}@gmail.com`) =>
  env.authenticatedContext(uid, { email }).firestore();
const guestDb = () => env.unauthenticatedContext().firestore();

const reading = (overrides = {}) => ({
  firstWord: '',
  markedLines: [],
  conversation: [],
  evidenceLines: [],
  interpretation: '',
  isSaved: false,
  hasOpenedComparison: false,
  isPublic: false,
  ...overrides,
});

const DAY = 24 * 60 * 60 * 1000;

/** 규칙을 끄고 미리 깔아 두는 데이터 */
async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

async function seedProfile(db, uid, { lastCounted = 0, badgeIds = [], total = 0 } = {}) {
  await setDoc(doc(db, 'users', uid), {
    nickname: `닉네임-${uid}`,
    totalReadingDays: total,
    lastCountedDate: Timestamp.fromMillis(lastCounted),
    badgeIds,
  });
}

async function seedConversation(db, ownerUid, poemId, empathyCount = 0) {
  const id = `${ownerUid}_${poemId}`;
  await setDoc(doc(db, 'publicConversations', id), {
    userId: ownerUid,
    poemId,
    firstWord: '부끄럼',
    summary: '요약',
    interpretation: '해석',
    empathyCount,
    evidenceLines: [2],
    createdAt: Timestamp.now(),
  });
  return id;
}

// ── 공개 대화 열람 잠금 (가장 중요한 규칙) ─────────────

describe('공개 대화: 그 시를 저장한 사람만 읽는다', () => {
  beforeEach(async () => {
    await seed(async (db) => {
      await seedConversation(db, OTHER, POEM);
      await seedConversation(db, OTHER, 'jindallae');
      await setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true, interpretation: '내 해석' }));
    });
  });

  test('저장한 시는 목록 질의(poemId 조건 + 최신순)가 된다', async () => {
    const q = query(
      collection(dbOf(ME), 'publicConversations'),
      where('poemId', '==', POEM),
      orderBy('createdAt', 'desc'),
    );
    await assertSucceeds(getDocs(q));
  });

  test('저장하지 않은 시는 목록 질의가 막힌다', async () => {
    const q = query(
      collection(dbOf(ME), 'publicConversations'),
      where('poemId', '==', 'jindallae'),
      orderBy('createdAt', 'desc'),
    );
    await assertFails(getDocs(q));
  });

  test('poemId 조건 없는 전체 목록은 막힌다', async () => {
    await assertFails(getDocs(collection(dbOf(ME), 'publicConversations')));
  });

  test('id로 하나 읽기: 저장한 시는 되고, 안 한 시는 막힌다', async () => {
    await assertSucceeds(getDoc(doc(dbOf(ME), 'publicConversations', `${OTHER}_${POEM}`)));
    await assertFails(getDoc(doc(dbOf(ME), 'publicConversations', `${OTHER}_jindallae`)));
  });

  test('내 id로 시작하는 문서는 없어도 읽힌다 (저장 트랜잭션의 존재 확인)', async () => {
    await assertSucceeds(getDoc(doc(dbOf(ME), 'publicConversations', `${ME}_jindallae`)));
  });

  test('로그인 안 하면 아무것도 못 읽는다', async () => {
    await assertFails(getDoc(doc(guestDb(), 'publicConversations', `${OTHER}_${POEM}`)));
  });
});

// ── 읽기 기록 ─────────────────────────────────────────

describe('읽기 기록: 나만, 잠금은 되돌릴 수 없다', () => {
  test('남의 읽기는 못 읽는다', async () => {
    await seed((db) => setDoc(doc(db, 'users', OTHER, 'readings', POEM), reading()));
    await assertFails(getDoc(doc(dbOf(ME), 'users', OTHER, 'readings', POEM)));
  });

  test('저장한 뒤 isSaved를 false로 되돌릴 수 없다', async () => {
    await seed((db) => setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true })));
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM), reading({ isSaved: false })));
  });

  test('대조를 연 뒤에는 해석을 고칠 수 없다', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', ME, 'readings', POEM),
        reading({ isSaved: true, hasOpenedComparison: true, interpretation: '처음' })));
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM),
      reading({ isSaved: true, hasOpenedComparison: true, interpretation: '고침' })));
  });

  test('저장 전에는 대조 열람을 켤 수 없다', async () => {
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM),
      reading({ hasOpenedComparison: true })));
  });

  test('공개로 저장한 뒤 비공개로 되돌릴 수 없다', async () => {
    await seed((db) =>
      setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true, isPublic: true })));
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM),
      reading({ isSaved: true, isPublic: false })));
  });

  test('저장 · 대조 열람 · 공개 뒤에도 대화는 비울 수 있다 (S11 기록 지우기)', async () => {
    const locked = { isSaved: true, hasOpenedComparison: true, isPublic: true, interpretation: '내 해석' };
    await seed((db) =>
      setDoc(doc(db, 'users', ME, 'readings', POEM),
        reading({ ...locked, conversation: [{ role: 'user', text: '가' }] })));
    await assertSucceeds(updateDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM), { conversation: [] }));
  });

  test('대화 · 멈춘 줄 목록이 너무 길면 막힌다', async () => {
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM),
      reading({ conversation: Array.from({ length: 201 }, () => ({ role: 'user', text: '가' })) })));
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM),
      reading({ markedLines: Array.from({ length: 101 }, (_, i) => i + 1) })));
  });

  test('해석 500자 · 낱말 20자를 넘으면 막힌다', async () => {
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM),
      reading({ interpretation: '가'.repeat(501) })));
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME, 'readings', POEM),
      reading({ firstWord: '가'.repeat(21) })));
  });
});

// ── 누적일수 ─────────────────────────────────────────

describe('누적일수: 하루(한국 시간)에 +1만, 서버 시각으로', () => {
  test('어제 센 사람은 오늘 +1 된다', async () => {
    await seed((db) => seedProfile(db, ME, { lastCounted: Date.now() - 2 * DAY, total: 3 }));
    await assertSucceeds(updateDoc(doc(dbOf(ME), 'users', ME), {
      totalReadingDays: increment(1),
      lastCountedDate: serverTimestamp(),
    }));
  });

  test('오늘 이미 셌으면 막힌다', async () => {
    await seed((db) => seedProfile(db, ME, { lastCounted: Date.now(), total: 3 }));
    await assertFails(updateDoc(doc(dbOf(ME), 'users', ME), {
      totalReadingDays: increment(1),
      lastCountedDate: serverTimestamp(),
    }));
  });

  test('+2는 막힌다', async () => {
    await seed((db) => seedProfile(db, ME, { lastCounted: Date.now() - 2 * DAY, total: 3 }));
    await assertFails(updateDoc(doc(dbOf(ME), 'users', ME), {
      totalReadingDays: increment(2),
      lastCountedDate: serverTimestamp(),
    }));
  });

  test('기기 시각을 lastCountedDate로 넣으면 막힌다', async () => {
    await seed((db) => seedProfile(db, ME, { lastCounted: Date.now() - 2 * DAY, total: 3 }));
    await assertFails(updateDoc(doc(dbOf(ME), 'users', ME), {
      totalReadingDays: increment(1),
      lastCountedDate: Timestamp.now(),
    }));
  });

  test('남의 누적일수는 못 올린다', async () => {
    await seed((db) => seedProfile(db, OTHER, { lastCounted: 0 }));
    await assertFails(updateDoc(doc(dbOf(ME), 'users', OTHER), {
      totalReadingDays: increment(1),
      lastCountedDate: serverTimestamp(),
    }));
  });
});

// ── 가입 · 닉네임 ─────────────────────────────────────

describe('가입: 닉네임 예약과 프로필을 함께', () => {
  const newProfile = (nickname) => ({
    nickname,
    totalReadingDays: 0,
    lastCountedDate: Timestamp.fromMillis(0),
    badgeIds: [],
  });

  test('닉네임 예약 + 프로필 생성을 한 번에 하면 된다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'nicknames', '조용한 별'), { userId: ME });
    batch.set(doc(db, 'users', ME), newProfile('조용한 별'));
    await assertSucceeds(batch.commit());
  });

  test('이미 있는 닉네임은 다시 예약할 수 없다', async () => {
    await seed((db) => setDoc(doc(db, 'nicknames', '조용한 별'), { userId: OTHER }));
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'nicknames', '조용한 별'), { userId: ME });
    batch.set(doc(db, 'users', ME), newProfile('조용한 별'));
    await assertFails(batch.commit());
  });

  test('gmail.com이 아닌 계정은 앱을 거치지 않아도 가입할 수 없다', async () => {
    const db = dbOf(ME, 'alice@naver.com');
    const batch = writeBatch(db);
    batch.set(doc(db, 'nicknames', '조용한 별'), { userId: ME });
    batch.set(doc(db, 'users', ME), newProfile('조용한 별'));
    await assertFails(batch.commit());
  });

  test('예약 없이 프로필만 만들 수 없다', async () => {
    await assertFails(setDoc(doc(dbOf(ME), 'users', ME), newProfile('조용한 별')));
  });

  test('누적일수 · 뱃지를 채운 채로 가입할 수 없다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'nicknames', '조용한 별'), { userId: ME });
    batch.set(doc(db, 'users', ME), { ...newProfile('조용한 별'), totalReadingDays: 99 });
    await assertFails(batch.commit());
  });
});

// ── 최종 저장: 읽기 · 뱃지 · 공개 대화 ─────────────────

describe('최종 저장: 뱃지와 공개 대화는 저장과 함께만', () => {
  beforeEach(async () => {
    await seed((db) => seedProfile(db, ME));
  });

  const publicConversation = (overrides = {}) => ({
    userId: ME,
    poemId: POEM,
    firstWord: '부끄럼',
    summary: '요약',
    interpretation: '내 해석',
    empathyCount: 0,
    evidenceLines: [2],
    createdAt: serverTimestamp(),
    ...overrides,
  });

  test('저장 + 뱃지 + 공개 대화를 한 번에 하면 된다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM),
      reading({ isSaved: true, isPublic: true, interpretation: '내 해석' }));
    batch.update(doc(db, 'users', ME), { badgeIds: arrayUnion(POEM) });
    batch.set(doc(db, 'publicConversations', `${ME}_${POEM}`), publicConversation());
    await assertSucceeds(batch.commit());
  });

  test('저장하지 않은 시의 뱃지를 배열 앞에 끼워 넣을 수 없다 (PR #13 리뷰)', async () => {
    await seed(async (db) => {
      await seedProfile(db, ME, { badgeIds: [] });
      await setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true }));
    });
    // 저장한 시(seosi)를 끝에 두고 저장 안 한 시를 앞에 — 둘이 늘어난 것이라 막힌다
    await assertFails(updateDoc(doc(dbOf(ME), 'users', ME), { badgeIds: ['jindallae', POEM] }));
    // seosi 뱃지가 이미 있을 때 앞에 끼우기
    await seed((db) => seedProfile(db, ME, { badgeIds: [POEM] }));
    await assertFails(updateDoc(doc(dbOf(ME), 'users', ME), { badgeIds: ['jindallae', POEM] }));
  });

  test('같은 뱃지를 중복으로 넣을 수 없다 (PR #13 리뷰)', async () => {
    await seed(async (db) => {
      await seedProfile(db, ME, { badgeIds: [POEM] });
      await setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true }));
    });
    await assertFails(updateDoc(doc(dbOf(ME), 'users', ME), { badgeIds: [POEM, POEM] }));
  });

  test('저장하지 않은 시의 뱃지는 받을 수 없다', async () => {
    await assertFails(updateDoc(doc(dbOf(ME), 'users', ME), { badgeIds: arrayUnion(POEM) }));
  });

  test('비공개 저장에서는 공개 대화를 만들 수 없다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM),
      reading({ isSaved: true, isPublic: false, interpretation: '내 해석' }));
    batch.set(doc(db, 'publicConversations', `${ME}_${POEM}`), publicConversation());
    await assertFails(batch.commit());
  });

  test('남의 이름 · 남의 id로는 만들 수 없다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM),
      reading({ isSaved: true, isPublic: true, interpretation: '내 해석' }));
    batch.set(doc(db, 'publicConversations', `${OTHER}_${POEM}`), publicConversation({ userId: OTHER }));
    await assertFails(batch.commit());
  });

  test('공감 수를 채운 채로 만들 수 없다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM),
      reading({ isSaved: true, isPublic: true, interpretation: '내 해석' }));
    batch.set(doc(db, 'publicConversations', `${ME}_${POEM}`), publicConversation({ empathyCount: 5 }));
    await assertFails(batch.commit());
  });
});

// ── 공감 ─────────────────────────────────────────────

describe('공감: 공감 문서와 함께 ±1, 저장한 사람만', () => {
  let conversationId;

  beforeEach(async () => {
    await seed(async (db) => {
      conversationId = await seedConversation(db, OTHER, POEM, 3);
    });
  });

  test('저장한 사람은 공감 문서 + 공감 수 +1을 함께 하면 된다', async () => {
    await seed((db) => setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true })));
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'publicConversations', conversationId, 'empathies', ME), {});
    batch.update(doc(db, 'publicConversations', conversationId), { empathyCount: increment(1) });
    await assertSucceeds(batch.commit());
  });

  test('공감 문서 없이 수만 올릴 수 없다', async () => {
    await seed((db) => setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true })));
    await assertFails(updateDoc(doc(dbOf(ME), 'publicConversations', conversationId),
      { empathyCount: increment(1) }));
  });

  test('저장하지 않은 사람은 공감할 수 없다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'publicConversations', conversationId, 'empathies', ME), {});
    batch.update(doc(db, 'publicConversations', conversationId), { empathyCount: increment(1) });
    await assertFails(batch.commit());
  });

  test('해석 · 요약은 고칠 수 없다', async () => {
    await seed((db) => setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ isSaved: true })));
    await assertFails(updateDoc(doc(dbOf(ME), 'publicConversations', conversationId),
      { interpretation: '바꿈' }));
  });
});

// ── 멈춤 집계 ─────────────────────────────────────────

describe('멈춤 집계: 내 표시와 함께 한 줄씩', () => {
  test('내 markedLines를 바꾸면서 한 줄 +1은 된다', async () => {
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM), reading({ markedLines: [6] }));
    batch.set(doc(db, 'lineStops', POEM), { counts: { 6: increment(1) } }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  test('내 표시 없이 집계만 올릴 수 없다', async () => {
    await assertFails(setDoc(doc(dbOf(ME), 'lineStops', POEM),
      { counts: { 6: increment(1) } }, { merge: true }));
  });

  test('표시를 끄면 그 줄만 정확히 -1 된다', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'lineStops', POEM), { counts: { 6: 4 } });
      await setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ markedLines: [6] }));
    });
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM), reading({ markedLines: [] }));
    batch.set(doc(db, 'lineStops', POEM), { counts: { 6: increment(-1) } }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  test('공유 집계를 999999나 -100으로 바꿀 수 없다 (PR #13 리뷰)', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'lineStops', POEM), { counts: { 3: 5 } });
      await setDoc(doc(db, 'users', ME, 'readings', POEM), reading({ markedLines: [1] }));
    });
    for (const value of [999999, -100]) {
      const db = dbOf(ME);
      const batch = writeBatch(db);
      batch.set(doc(db, 'users', ME, 'readings', POEM), reading({ markedLines: [1, 2] }));
      batch.update(doc(db, 'lineStops', POEM), { counts: { 3: value } });
      await assertFails(batch.commit());
    }
  });

  test('표시한 줄과 다른 줄의 집계를 올릴 수 없다', async () => {
    await seed((db) => setDoc(doc(db, 'lineStops', POEM), { counts: { 3: 5 } }));
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM), reading({ markedLines: [6] }));
    batch.set(doc(db, 'lineStops', POEM), { counts: { 3: increment(1) } }, { merge: true });
    await assertFails(batch.commit());
  });

  test('한 번에 두 줄은 바꿀 수 없다', async () => {
    await seed((db) => setDoc(doc(db, 'lineStops', POEM), { counts: { 2: 3 } }));
    const db = dbOf(ME);
    const batch = writeBatch(db);
    batch.set(doc(db, 'users', ME, 'readings', POEM), reading({ markedLines: [2, 6] }));
    batch.set(doc(db, 'lineStops', POEM),
      { counts: { 2: increment(1), 6: increment(1) } }, { merge: true });
    await assertFails(batch.commit());
  });
});
