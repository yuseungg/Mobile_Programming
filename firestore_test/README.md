# firestore.rules 테스트

`firestore.rules`를 Firestore **에뮬레이터**(내 PC에서 도는 가짜 Firestore) 위에서 시험한다. 진짜 데이터베이스는 건드리지 않는다.

## 처음 한 번

- Node.js 20 이상
- Java 21 이상 — Android Studio에 들어 있는 것을 써도 된다
- Firebase CLI: `npm install -g firebase-tools`

Windows PowerShell에서 Android Studio의 Java를 쓰려면 창마다 한 번:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
```

## 실행

```powershell
cd firestore_test
npm install
npm test
```

처음에는 에뮬레이터를 내려받느라 1~2분 걸린다. 마지막에 `# fail 0`이 나오면 통과.

## 규칙을 실제 프로젝트에 올리기

테스트가 통과한 뒤 저장소 루트에서:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project yeobaek-e2386
```
