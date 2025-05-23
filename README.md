# IaC を使ったインフラ開発用のコンテナイメージ

IaC を使ったインフラの開発に必要な各種ソフトウェアをコンテイメージ化することで以下の機能を提供する。

- 端末の OS や各自の環境に影響されない統一された開発環境の提供
- 各種ツールの導入作業の負荷軽減

Terraform/Ansible/Docker/Kubernetes/CloudFormation の開発を主目的とする。

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
- tree

#### 言語系

- python
- pip

#### IaC

- Terraform
- tflint
- ansible

#### コンテナ

- docker
- kubectl
- helm

#### クラウド系

- aws cli
- sam cli
- ecs cli
- eksctl

#### CloudFormation

- cfn-lint
- cfn-guard
- sam

#### Github Actions

- act

### base イメージとツールのバージョン

以下のツールについては互換性の観点からバージョンの固定を行っている。

| ツール     | バージョン            |
| ---------- | --------------------- |
| base       | almalinux:9.4-minimal |
| terraform  | 1.7.4                 |
| ansible    | 8.7.0                 |
| docker cli | 1:25.0.3-1.el9        |
| kubectl    | v1.29.1               |
| aws cli    | 2.17.49               |
| sam cli    | v0.123.0              |
| ecscli     | v1.21.0               |
| eksctl     | v0.171.0              |

## コンテナイメージのビルドと起動

コマンドを実行してコンテナイメージをビルドする。

### Windows/Linux(amd64)の場合

```bash
docker build --build-arg BUILDARCH=amd64 --build-arg AWSCLIARCH=x86_64 --build-arg SAMCLIARCH=x86_64 -t iac_devcontainer:v1.5 .
```

### Mac 場合

```bash
docker build --build-arg BUILDARCH=arm64 --build-arg AWSCLIARCH=aarch64 --build-arg SAMCLIARCH=aarch64 -t iac_devcontainer:v1.5 .
```

アーキテクチャによる引数の値は以下の通り

| Architecture | BUILDARCH | AWSCLIARCH | SAMCLIARCH |
| ------------ | --------- | ---------- | ---------- |
| Intel        | amd64     | x86_64     | x86_64     |
| Apple        | arm64     | aarch64    | arm64      |

Volume を作成してからコンテナを作成する。

```bash
docker volume create iac-devcontainer-volume

docker create --name iac-devcontainer -v iac-devcontainer-volume:/work -v /run/podman/podman.sock:/var/run/docker.sock docker.sock iac-devcontainer:v1.5
```

GUI からコンテナを起動させる。

## コンテナに接続

VSCode の拡張機能「Dev Container」を導入する。

画面左下の「<>」をクリックして「Attach to Running Container」を選択して、bih-infra-devcontainer に接続する。

## コンテナの更新

新しいコンテナを起動する前に ibm-user のホームディレクトリを/work にバックアップする。

```bash
tar cvf /work/devuser_home.tar .aws .bash_profile .bashrc .gitconfig
```

GUI で現在のコンテナを削除する。Volume は削除されません。

上記で新しいコンテナをビルド＆起動したらホームディレクトリのバックアップをリストアする。

```bash
tar xvf /work/devuser_home.tar -C ~/
```

## Tag の更新

```sh
git tag v1.1
git push origin v1.1
```

## 更新履歴

- v1.5 2025/04/13 リファクタリング
- v1.4 2025/03/14 act-cli を追加
- v1.3 2025/03/02 vi と diff を追加
- v1.2 2025/03/02 tree を追加
- v1.1 2024/09/17 CloudFormation のツールを追加,base を almalinux:9.4-minimal に変更
- v1.0 2024/02/14 初版作成
