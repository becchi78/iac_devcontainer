# IaC を使ったインフラ開発用のコンテナイメージ

IaC を使ったインフラの開発に必要な各種ソフトウェアをコンテナイメージ化することで以下の機能を提供する。

- 端末の OS や各自の環境に影響されない統一された開発環境の提供
- 各種ツールの導入作業の負荷軽減
- マルチアーキテクチャ対応（Intel/AMD64 および Apple Silicon/ARM64）

Terraform/Ansible/Docker/Kubernetes/CloudFormation の開発を主目的とする。

## コンテナ詳細

### BASE

業務で使用することの多い RHEL 系の AlmaLinux を使用する。
コンテナイメージの軽量化を図るため、minimal 系のイメージを使用する。
マルチアーキテクチャ対応により、Intel/AMD (x86_64) および Apple Silicon (arm64) の両方で動作する。

### 導入ツール

開発用コンテナには以下のツールが予め導入してある。

#### コマンド系

- curl
- wget
- which
- tar
- zip
- unzip
- nettool 系
- git
- jq
- tree
- vi
- diff
- yq

#### 言語系

- Python 3.12（uv で管理）
- Node.js v22.11.0
- npm

#### Python 開発ツール

- uv（高速パッケージマネージャー）
- Ruff（高速リンター/フォーマッター）
- mypy（型チェッカー）
- pytest（テストフレームワーク）
- Poetry（依存関係管理）
- IPython
- JupyterLab
- pandas/numpy

#### AI 開発支援

- Claude Code CLI（@anthropic-ai/claude-code）

#### IaC

- Terraform
- tflint
- Ansible

#### コンテナ

- Docker CLI
- kubectl

#### クラウド系

- AWS CLI
- SAM CLI
- ECS CLI
- eksctl

#### CloudFormation

- cfn-lint
- cfn-guard
- SAM

#### GitHub Actions

- act

### base イメージとツールのバージョン

以下のツールについては互換性の観点からバージョンの固定を行っている。

| ツール     | バージョン            |
| ---------- | --------------------- |
| base       | almalinux:9.6-minimal |
| Python     | 3.12（uv で管理）     |
| Node.js    | v22.11.0              |
| uv         | 0.8.19                |
| Ruff       | 0.8.4                 |
| Terraform  | 1.7.4                 |
| Ansible    | 8.7.0                 |
| Docker CLI | 1:25.0.3-1.el9        |
| kubectl    | v1.29.1               |
| AWS CLI    | 2.17.49               |
| SAM CLI    | v1.123.0              |
| ECS CLI    | v1.21.0               |
| eksctl     | v0.171.0              |

## Docker Hub からの利用（推奨）

ビルド済みのイメージが Docker Hub で公開されており、マルチアーキテクチャ対応となっています。

```bash
# 最新版を取得（自動的に適切なアーキテクチャを選択）
docker pull becchi78/iac_devcontainer:v1.6

# Volume を作成
docker volume create iac-devcontainer-volume

# コンテナを作成・起動
docker run -d --name iac-devcontainer \
  -v iac-devcontainer-volume:/work \
  -v /var/run/docker.sock:/var/run/docker.sock \
  becchi78/iac_devcontainer:v1.6
```

## コンテナイメージのビルド（ローカルビルド）

ソースからビルドする場合は、設定ファイルを配置してからビルドする。

```bash
# 設定ファイルを配置（configディレクトリに ruff.toml, mypy.ini, pytest.ini を配置）
mkdir config
cp path/to/config/files/* config/

# ビルド（プラットフォームに応じて自動選択）
docker build -t iac_devcontainer:v1.6 .
```

### 手動でアーキテクチャを指定する場合

#### Windows/Linux (AMD64) の場合

```bash
docker build --build-arg BUILDARCH=amd64 --build-arg AWSCLIARCH=x86_64 --build-arg SAMCLIARCH=x86_64 -t iac_devcontainer:v1.6 .
```

#### Mac (Apple Silicon) の場合

```bash
docker build --build-arg BUILDARCH=arm64 --build-arg AWSCLIARCH=aarch64 --build-arg SAMCLIARCH=arm64 -t iac_devcontainer:v1.6 .
```

アーキテクチャによる引数の値は以下の通り

| Architecture  | BUILDARCH | AWSCLIARCH | SAMCLIARCH |
| ------------- | --------- | ---------- | ---------- |
| Intel/AMD     | amd64     | x86_64     | x86_64     |
| Apple Silicon | arm64     | aarch64    | arm64      |

## コンテナに接続

### VS Code での接続（推奨）

VSCode の拡張機能「Dev Container」を導入する。

画面左下の「<>」をクリックして「Attach to Running Container」を選択して、iac-devcontainer に接続する。

### コマンドラインでの接続

```bash
docker exec -it iac-devcontainer /bin/bash
```

## Python 開発環境の使い方

### パッケージ管理（uv）

```bash
# パッケージのインストール（高速）
uv pip install --system fastapi

# 仮想環境の作成
uv venv
source .venv/bin/activate
```

### コード品質管理

```bash
# Ruffでリント＆フォーマット
ruff check .
ruff format .

# 型チェック
mypy src/

# テスト実行
pytest tests/
```

### AI 支援開発

```bash
# Claude Code を使用
npx claude-code "Help me implement this function..."
```

## コンテナの更新

新しいコンテナを起動する前に devuser のホームディレクトリを /work にバックアップする。

```bash
tar cvf /work/devuser_home.tar .aws .bash_profile .bashrc .gitconfig .config
```

GUI で現在のコンテナを削除する。Volume は削除されません。

上記で新しいコンテナをビルド＆起動したらホームディレクトリのバックアップをリストアする。

```bash
tar xvf /work/devuser_home.tar -C ~/
```

## GitHub Actions での自動ビルド

リポジトリにタグをプッシュすると、GitHub Actions により自動的にマルチアーキテクチャイメージがビルドされ、Docker Hub にプッシュされます。

```bash
git tag v1.6
git push origin v1.6
```

## 更新履歴

- v1.6 2025/09/23 Python 3.12 移行、uv/Ruff 導入、Node.js 22 追加、Claude Code CLI 追加、マルチアーキテクチャ対応
- v1.5 2025/04/13 リファクタリング
- v1.4 2025/03/14 act-cli を追加
- v1.3 2025/03/02 vi と diff を追加
- v1.2 2025/03/02 tree を追加
- v1.1 2024/09/17 CloudFormation のツールを追加、base を almalinux:9.4-minimal に変更
- v1.0 2024/02/14 初版作成
