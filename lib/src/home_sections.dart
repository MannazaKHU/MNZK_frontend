enum HomeSection { intro, group, time, preference, result }

extension HomeSectionLabel on HomeSection {
  String get label => const {
    HomeSection.intro: '소개',
    HomeSection.group: '그룹 만들기',
    HomeSection.time: '시간 맞추기',
    HomeSection.preference: '취향 모으기',
    HomeSection.result: '장소 추천',
  }[this]!;
}
