// 주인: C — Firebase 관련 상수
//
// 비밀값이 아니다. google-services.json에도 들어 있는 공개 식별자다 (PR #11 결정).

/// 구글 로그인(google_sign_in 7)에 넘기는 웹 클라이언트 ID.
/// google-services.json의 oauth_client 중 client_type 3.
const googleServerClientId =
    '1070919901756-l3agtkv8jblg1qvd6bbn39ehuiad3i5g.apps.googleusercontent.com';

/// 가입 · 로그인을 허용하는 이메일 도메인 (기획서 5장).
const allowedEmailDomain = '@gmail.com';

bool isAllowedEmail(String email) =>
    email.trim().toLowerCase().endsWith(allowedEmailDomain);
