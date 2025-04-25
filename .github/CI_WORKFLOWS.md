# CI Workflows

## ファイル構成

- **`ci-cd-pipeline.yml`**: メインとなる統合CI/CDパイプラインですPull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の他のワークフローを順次実行します
- **`run-tests.yml`**: アプリのビルドとテスト（ユニット・UI）を実行する再利用可能ワークフロー`.github/scripts/` 配下の関数定義ファイルを `source` し、必要な関数（シミュレータ選択、ビルド、テスト実行、結果検証など）を直接呼び出します
- **`build-unsigned-archive.yml`**: 署名なしのアーカイブ（.xcarchive）を作成する再利用可能ワークフロー`.github/scripts/` 配下の関数定義ファイルを `source` し、必要な関数（アーカイブビルド、結果検証など）を直接呼び出します
- **`code-quality.yml`**: コード品質チェック（SwiftFormat, SwiftLint）を実行します
- **`test-reporter.yml`**: テスト結果のレポートを作成し、PRにコメントします
- **`copilot-review.yml`**: GitHub CopilotによるPRレビューを自動化します

## CIの特徴

### ワークフローの分割
メインの`ci-cd-pipeline.yml`が、テスト、コード品質チェック、アーカイブビルドなどの個別の再利用可能ワークフローを呼び出す構造になっています
コアなビルド・テスト・アーカイブ処理は、`.github/scripts/` 配下のシェルスクリプト（主に `run-local-ci.sh`）に関数として定義され、各ワークフローやローカル検証スクリプトが必要に応じてこれらを呼び出します

### 包括的なビルドプロセスの検証
Pull Requestや`main`ブランチへのプッシュ時に、以下の自動チェックを実行します
- コードフォーマット (SwiftFormat) と静的解析 (SwiftLint)
- ユニットテストとUIテスト、およびそれらの結果（xcresult）の検証
- リリース設定でのアーカイブビルドと結果の検証（`main`ブランチプッシュ時）

### Pull Request に自動でレビュー
Pull Requestに対して、テスト結果のレポート、GitHub Copilotによる自動レビューリクエスト、パイプライン全体の完了ステータス通知を行います

### 成果物管理
- 成果物管理: ビルドやテストの成果物はGitHub Artifactsとしてアップロード・管理されます
- 出力先を統一: 全てのビルド・テスト関連の成果物は、一貫して `ci-outputs/` ディレクトリ以下に出力されます

## 機能詳細

### `ci-cd-pipeline.yml` (メインパイプライン)

- **トリガー**: `main`/`master`へのPush、`main`/`master`ターゲットのPR、手動実行
- **処理**:
    1.  コード品質チェック (`code-quality.yml`)
    2.  ビルドとテスト実行 (`run-tests.yml`)
    3.  テスト結果レポート (PR時, `test-reporter.yml`)
    4.  Copilotレビュー依頼 (PR時, `copilot-review.yml`)
    5.  アーカイブビルド検証 (`main` Push時, `build-unsigned-archive.yml`)
    6.  パイプライン完了ステータス通知 (PR時)

### `run-tests.yml` (テスト実行)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  共通・ビルドステップ関数を `source`
    2.  watchOSシミュレータを選択
    3.  テスト用ビルド (`build_for_testing`)
    4.  ユニットテスト実行と結果検証 (`run_unit_tests`, `verify_unit_test_results`)
    5.  UIテスト実行と結果検証 (`run_ui_tests`, `verify_ui_test_results`)
    6.  JUnit XMLレポート生成
    7.  テスト結果 (`.xcresult`, `.xml`) をアーティファクト (`test-results`) としてアップロード

### `build-unsigned-archive.yml` (署名なしアーカイブ作成)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  共通・ビルドステップ関数 (`build-archive.sh`) を `source`
    2.  アーカイブビルド (`build_archive_step`)
    3.  アーカイブ内容検証 (`verify_archive_step`)
    4.  `.xcarchive` をアーティファクト (`unsigned-archive`) としてアップロード

### `code-quality.yml` (コード品質チェック)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  Mintでツール (SwiftFormat, SwiftLint) をインストール
    2.  SwiftFormatを実行
    3.  SwiftLint (`--strict`) を実行
    4.  `git diff` でフォーマット変更がないか確認

### `test-reporter.yml` (テスト結果レポート)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し (PR時)
- **処理**:
    1.  `test-results` アーティファクトをダウンロード
    2.  JUnitレポートからGitHub Checksに結果を表示
    3.  PRにテスト結果サマリーをコメント

### `copilot-review.yml` (Copilotレビュー依頼)

- **トリガー**: `ci-cd-pipeline.yml` から `workflow_call` で呼び出し (PR時)
- **処理**:
    1.  Copilotをレビュアーに追加
    2.  失敗時にエラーコメントをPRに投稿

## 使用方法

メインパイプライン (`ci-cd-pipeline.yml`) は以下のタイミングで自動実行されます:

- **プッシュ時**: `main` または `master` ブランチへのプッシュ
- **PR作成/更新時**: `main` または `master` ブランチをターゲットとするPull Request
- **手動実行**: GitHub Actionsタブから `ci-cd-pipeline.yml` を選択して実行可能

個別のワークフローは通常、直接実行するのではなく、`ci-cd-pipeline.yml` によって呼び出されます

## ローカルでのCIプロセスの検証

GitHub Actions で実行される主要なCIステップ（テスト、アーカイブ）のコアロジックをローカルで検証するためのスクリプト (`.github/scripts/run-local-ci.sh`) を用意していますこのスクリプトは、`.github/scripts/` 配下の関数定義ファイルを `source` し、コマンドライン引数に基づいて適切な関数を呼び出すことで、CIの主要な処理フローを再現します

初回実行前に、以下のコマンドでスクリプトに実行権限を付与してください
```shell
$ chmod +x .github/scripts/find-simulator.sh
$ chmod +x .github/scripts/run-local-ci.sh
```

### ビルドを含む検証

ローカル環境でビルドからテストやアーカイブを実行し、CIワークフローで実行されるコアな処理が期待通りかを確認します

```shell
# 全てのステップ (ビルド、単体テスト実行・検証、UIテスト実行・検証、アーカイブビルド・検証) を実行
$ ./.github/scripts/run-local-ci.sh

# テスト用ビルド + 単体テストとUIテストの両方を実行・検証
$ ./.github/scripts/run-local-ci.sh --all-tests

# テスト用ビルド + 単体テストのみを実行・検証
$ ./.github/scripts/run-local-ci.sh --unit-test

# テスト用ビルド + UIテストのみを実行・検証
$ ./.github/scripts/run-local-ci.sh --ui-test

# ビルド + アーカイブのみを実行・検証
$ ./.github/scripts/run-local-ci.sh --archive-only
```

## 技術仕様

- Xcodeバージョン: 16.2
- テスト環境: watchOS シミュレータ
- 依存ツール管理: Mint (SwiftFormat, SwiftLint), Homebrew (xcbeautify), RubyGems (xcpretty)
- アーティファクト保持期間: ビルド関連 = 1日、テスト結果/アーカイブビルド = 7日
- 出力先ディレクトリ: `ci-outputs/`
  - `test-results/`: テストの結果 (`.xcresult`, `.xml`)
  - `production/`: リリース用（署名なし）のアーカイブの結果

