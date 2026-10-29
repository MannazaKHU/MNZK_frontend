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

## 프론트엔드 범위

백엔드, 로그인, 지도 검색, 채팅, 프로필 데이터 연동은 포함하지 않습니다. 원본에서도 메뉴만 있던 맵·채팅·프로필은 준비 중 알림을 표시합니다.

그룹 생성·코드 참여·제출은 **메모리 기반 체험 모드**입니다. 코드 입력 시 예시 그룹으로 이동하며, 제출하면 예시 참여자의 일정이 채워집니다. 실제 다른 기기와 그룹 코드나 입력을 공유하지 않으며 새로고침하면 초기화됩니다. 화면 상단에 체험 모드와 예시 참여자임을 표시합니다. 장소 추천 또한 실제 지도·장소 API 연결 전의 프론트엔드 예시이며 결과 화면에 이를 명시합니다.

실제 API를 연결하려면 `lib/src/meeting_controller.dart`의 `createGroup()`, `joinGroup()`, `submit()`을 교체하고, 그룹원 상태를 서버의 실시간 구독 또는 폴링 결과로 갱신하세요. `ScheduleDraft.toJson()`이 입력 직렬화를 제공합니다. 예시 생성용 `_fillExample()`과 타이머는 실서비스에서 제거하세요. 프라이버시는 서버에서도 별도 접근 제어가 필요합니다.

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
