# IaCを使ったインフラ開発用のコンテナイメージ

IaCを使ったインフラの開発に必要な各種ソフトウェアをコンテイメージ化することで以下の機能を提供する。

- 端末の OS や各自の環境に影響されない統一された開発環境の提供
- 各種ツールの導入作業の負荷軽減

Terraform/Ansible/Docker/Kubernetes の開発を主目的とする。

## コンテナ詳細

### BASE

業務で使用することの多い RHEL 系の AlmaLinux を使用する。
コンテナイメージの軽量化を図るため、minimal 系のイメージを使用する。
アーキテクチャは特別な要件がない限り x86-64 とする。

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

#### 言語系

- python
- pip

#### IaC

- Terraform
- ansible

#### コンテナ

- docker
- kubectl
- helm

#### クラウド系

- aws cli
- ecs cli
- eksctl

### base イメージとツールのバージョン

以下のツールについては互換性の観点からバージョンの固定を行っている。
|ツール|バージョン|
|---|---|
|base|almalinux:9.3-minimal|
|terraform|1.7.4|
|ansible|8.7.0|
|docker cli|1:25.0.3-1.el9|
|kubectl|v1.29.1|
|ecscli|v1.21.0|
|eksctl|v0.171.0|

# 更新履歴

- v1.0 2024/2/14 初版作成
