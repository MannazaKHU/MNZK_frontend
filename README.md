# 만나자쿠 Flutter 프론트엔드

제공된 `만나자쿠 html v1.html`을 기준으로 Flutter/Dart 위젯으로 옮긴 웹 프론트엔드입니다. HTML을 WebView에 넣지 않고 화면, 입력 기능, 반응형 레이아웃과 인터랙션을 직접 구현했습니다. 호스팅·배포 설정은 포함하지 않습니다.

## 실행

Flutter 3.44 / Dart 3.12 환경에서 확인했습니다.

```sh
cd /Users/iseungju/Desktop/GGJ/mannajaku_flutter
flutter pub get
flutter run -d chrome
```

웹 배포용 파일만 빌드하려면:

```sh
flutter build web
```

출력은 `build/web/`입니다. 하위 경로에서 서비스할 때는 `flutter build web --base-href /경로/`를 사용하세요.

## Railway 배포

저장소 루트의 `Dockerfile`을 Railway가 자동 감지합니다. 빌드 단계에서 Flutter Web release 번들을 만들고, 실행 단계에서는 Caddy가 Railway의 `PORT` 환경 변수로 정적 파일을 제공합니다.

1. Railway에서 이 GitHub 저장소를 서비스로 연결합니다.
2. 기존에 직접 입력한 Build Command와 Start Command가 있다면 비워 둡니다.
3. 새 배포를 실행합니다.
4. 배포가 활성화되면 **Settings → Networking → Generate Domain**에서 공개 주소를 만듭니다.

`railway.json`에는 Dockerfile 빌더와 `/` 상태 확인 경로가 설정되어 있습니다. Flutter 렌더러 파일도 컨테이너에 포함되도록 `--no-web-resources-cdn`으로 빌드하므로 실행 시 외부 Flutter CDN에 의존하지 않습니다.

### 백엔드 API 연결

프론트는 `API_BASE_URL` Dart define으로 MeetFlow FastAPI 주소를 받습니다. Railway 프론트 서비스의 Variables에 백엔드 공개 주소를 설정하고 재배포하세요.

```dotenv
API_BASE_URL=https://<백엔드-서비스>.up.railway.app
```

`Dockerfile`이 이 값을 빌드 인자로 받아 `--dart-define=API_BASE_URL=...`에 전달합니다. URL 끝의 `/`는 있어도 자동으로 정리됩니다. 값이 비어 있으면 로컬 UI 테스트를 위한 체험 모드가 동작합니다.

백엔드 Railway 서비스에는 실제 프론트 origin을 허용해야 합니다.

```dotenv
CORS_ORIGINS=https://ggj.com
```

로컬 프론트도 함께 허용하려면 쉼표로 구분합니다.

```dotenv
CORS_ORIGINS=https://ggj.com,http://localhost:8080,http://127.0.0.1:8080
```

연동되는 API는 그룹 생성, 초대 링크 참여, Bearer 토큰 기반 응답 제출, 모임 상태 조회와 장소 추천 결과입니다. 대기 화면은 3초마다 상태를 조회하며 `recommended` 또는 `finalized`가 되면 결과 화면으로 전환합니다.

## 구현된 화면과 동작

- 원본 v1의 초록 테마, 밑줄 제목, 초대 카드, 장식 아이콘, 둥근 카드와 버튼
- 소개·그룹·시간·취향·장소 추천으로 이동하는 상단 스크롤 내비게이션
- 그룹 만들기부터 장소 추천까지 설명하는 반응형 기능 소개 섹션과 CTA
- 버튼 hover 상승, 화살표 이동, 빛 반사, press 축소 효과와 로고·카드 hover 효과
- 운영체제의 동작 줄이기 설정(`prefers-reduced-motion`)에 대응하는 애니메이션 비활성화
- 데스크톱의 좌우 분할 레이아웃과 왼쪽 진행 단계, 모바일의 세로 배치와 가로 단계 목록
- 시스템 설정에 따른 라이트·다크 테마, 화면 전환 애니메이션
- 그룹 이름 입력, 2~12명 인원 선택, 6자리 코드 생성 및 클립보드 복사
- 그룹 코드 입력과 형식 검증
- 이름 입력, 달 이동, 여러 날짜 선택·해제
- 06:00~24:00의 30분 단위 시간표, 여러 날짜에 걸친 사각형 드래그 선택·해제, 가장자리 자동 스크롤
- 시간표에서 Tab으로 칸 이동, Space/Enter로 선택·해제
- 출발지·선호·기피 조건 입력, 이전 단계 이동 시 값 유지
- 제출 전 요약, 예시 그룹원 대기 상태, 입력 수정
- 최대 인원이 가능한 연속 시간의 1~3순위 카드, 익명 인원 수 히트맵, 모은 의견
- 결과 링크 복사와 예시 장소 추천 카드, 약도, 점수, 추천 이유, 이동시간 펼치기

## 연동 범위

`MannazaKHU/MNZK_backend`의 MeetFlow API v3 계약에 맞춰 그룹 생성, 초대 링크 참여, 일정·출발지·선호·비선호 제출, 참여 현황 조회, 공통 일정과 장소 추천 결과를 연결합니다. 생성·참여 시 받은 참여자 토큰은 이후 요청의 Bearer 인증에 사용합니다.

계정 로그인, 채팅과 프로필은 아직 포함하지 않습니다. `API_BASE_URL`이 비어 있는 로컬 UI 테스트에서는 기존 메모리 기반 체험 모드가 대신 동작하며, 이때만 예시 참여자와 예시 장소를 표시합니다.

## 코드 구조

```text
lib/
  main.dart                      # 앱 시작
  src/
    app.dart                     # 앱 테마, 헤더, 화면 전환
    theme.dart                   # 원본 색상과 공통 스타일
    models.dart                  # 입력 모델, 연속 시간/추천 계산
    meeting_controller.dart      # 진행 상태, 검증, 체험 데이터
    pages/
      home_page.dart             # 시작 화면과 코드 입력
      flow_page.dart             # 그룹/일정/취향/결과 화면
    widgets/
      common.dart                # 버튼, 카드, 제목, 알림
      date_calendar.dart         # 여러 날짜를 고르는 달력
      time_grid.dart             # 드래그 시간표와 결과 히트맵
      invitation_scene.dart      # 시작 화면 초대 카드와 배경
```

Noto Sans KR 및 Outfit 폰트를 `assets/fonts/`에 포함했습니다. 각 폰트의 SIL Open Font License 파일을 함께 제공합니다. 외부 이미지나 별도 UI 패키지 없이 Flutter SDK로 화면을 구성합니다.

## 검증

```sh
flutter analyze
flutter test
flutter build web
```
