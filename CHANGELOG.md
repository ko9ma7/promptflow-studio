## v2.1.1 — GitHub 업로드 충돌 수정 (2026-10-28)

- `github-bootstrap.cmd`, `github-update.cmd`: 원격 main의 최신 커밋을 fetch/merge한 다음 force 없이 push하도록 수정
- `git-safe-sync.cmd`: 공통 조상에 따른 fast-forward/merge 및 서로 다른 최초 이력에 대한 제한적인 선택 병합
- `github-repair-push.cmd`: 기존 push 실패 후 로컬 커밋을 재사용해 업로드를 복구하는 진입점
- README/USER_GUIDE: `fetch first` 오류 복구와 데이터 보존 기준 설명

# Changelog

## 2.0.0 — 강의 3단계 기본 제작 흐름 중심 개편 (2026-10-28)

- 기존 복잡한 페이지·고급 기능 우선 흐름에서 **기본 초안 → 기본 수정 → 선택 모션**으로 주요 경로 변경
- HTML 슬라이드 / HTML 보고서 / PPT 양식 빠른 선택과 추천 7페이지 구성
- 기본 수정 8종, 고급 효과 4종, 모션 5종을 프롬프트·설명·복사 기능으로 분리
- HTML 상시 편집·배포 HTML의 편집 UI 제외·HTML 재불러오기 요구조건 기본 삽입
- PPT 비율 및 이미지형·편집형 PPTX 선택 지침 추가
- 7종의 별도 첨부용 프롬프트 파일, README·매뉴얼 개정
- 기존 AI 답변 평가·재질문·GitHub Pages 배포 자동화 기능 유지

# 변경 이력

## 1.0.0 — 2026-10-28
- 8개 제작 대분류와 조건별 소분류·질문
- 페이지/장표/장면별 콘텐츠·레이아웃·인터랙션 설계
- 지침 프리셋 및 GitHub Pages 기본 패키지
- 실시간 마스터 프롬프트, Markdown 복사·다운로드
- AI 결과 수동 입력, 수용 기준 검수, 최소 범위 수정 요청·이력
- 브라우저 로컬 저장, JSON 백업/복원 및 다중 프로젝트
- GitHub Actions + Windows 최초/추가 업로드 CMD, About 자동화
