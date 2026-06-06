### BASE
FROM almalinux:9.8-minimal
    #https://repo.almalinux.org/almalinux/9/isos/x86_64/

### ENV
ENV TERRAFORM_VERSION=1.15.5 \
    #https://releases.hashicorp.com/terraform/
    ANSIBLE_VERSION=14.0.0 \
    #ansible core 2.21
    #https://docs.ansible.com/ansible/latest/roadmap/ansible_roadmap_index.html
    DOCKERCLI_VERSION=1:29.5.3-1.el9 \
    #https://download.docker.com/linux/centos/9/x86_64/stable/Packages/
    KUBECTL_VERSION=v1.36.1 \
    #https://dl.k8s.io/release/stable.txt
    #https://github.com/kubernetes/kubectl/tags
    AWSCLI_VERSION=2.34.61 \
    #https://github.com/aws/aws-cli
    SAM_VERSION=v1.160.0 \
    #https://github.com/aws/aws-sam-cli
    EKSCTL_VERSION=v0.227.0 \
    #https://github.com/eksctl-io/eksctl
    PYTHON_VERSION=3.12 \
    #Python version for uv
    NODE_VERSION=v22.22.3 \
    #for Claude Code CLI (https://nodejs.org/dist/)
    UV_VERSION=0.11.19 \
    #https://github.com/astral-sh/uv
    RUFF_VERSION=0.15.15 \
    #https://github.com/astral-sh/ruff
    CHECKOV_VERSION=3.2.532 \
    #https://github.com/bridgecrewio/checkov
    GH_VERSION=v2.92.0
    #https://github.com/cli/cli

### ARG
ARG BUILDARCH
ARG AWSCLIARCH
ARG SAMCLIARCH

### tools (gcc等のビルドツールを除外)
RUN microdnf update -y && \
    microdnf install -y epel-release yum-utils wget sudo which tar zip bind-utils git jq tree vi diffutils glibc-langpack-ja && \
    microdnf clean all && \
    rm -rf /var/cache/yum/* && \
    rm -rf /tmp/*

### TimeZone & LANG
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

### Install uv and Python 3.12
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    uv --version && \
    # Create global virtual environment with Python 3.12
    uv venv /opt/pyenv --python 3.12 && \
    /opt/pyenv/bin/python --version

ENV PATH="/opt/pyenv/bin:/usr/local/bin:$PATH" \
    VIRTUAL_ENV=/opt/pyenv

### Python Development Environment Setup
# Install Ruff (Python linter and formatter)
RUN uv tool install ruff==${RUFF_VERSION} && \
    ln -sf /root/.local/share/uv/tools/ruff/bin/ruff /usr/local/bin/ruff && \
    ruff --version

# Install Python development tools using uv
RUN uv pip install \
    mypy \
    pytest \
    pytest-cov \
    pytest-mock \
    pytest-asyncio \
    pytest-xdist \
    ipython \
    poetry \
    pre-commit \
    debugpy \
    python-lsp-server[all] \
    notebook \
    jupyterlab \
    pandas \
    numpy \
    requests \
    pydantic \
    python-dotenv

### Node.js and Claude Code CLI - Binary installation with PATH fix
# Node.jsを公式バイナリから直接インストール
RUN if [ "${BUILDARCH}" = "amd64" ]; then \
        NODE_ARCH="x64"; \
    elif [ "${BUILDARCH}" = "arm64" ]; then \
        NODE_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: ${BUILDARCH}" && exit 1; \
    fi && \
    curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${NODE_ARCH}.tar.gz" -o node.tar.gz && \
    tar -xzf node.tar.gz -C /usr/local --strip-components=1 && \
    rm node.tar.gz && \
    node --version && \
    npm --version && \
    npm install -g @anthropic-ai/claude-code

### Terraform
RUN curl -OL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip && \
    unzip -q terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip -d /usr/local/bin && \
    rm terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    tflint --version

### Ansible - Install using uv
RUN uv pip install ansible==${ANSIBLE_VERSION} && \
    ansible --version

### Docker & Kubernetes
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    microdnf -y install dnf-plugins-core docker-ce-cli-${DOCKERCLI_VERSION} && \
    curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${BUILDARCH}/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm ./get_helm.sh && \
    microdnf clean all && \
    rm -rf /var/cache/yum/* && \
    rm -rf /tmp/*

### AWS
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLIARCH}-${AWSCLI_VERSION}.zip" -o "awscliv2.zip" && \
    unzip -q awscliv2.zip && \
    ./aws/install && \
    rm awscliv2.zip && \
    rm -rf ./aws

RUN curl -sLO "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_${BUILDARCH}.tar.gz" && \
    tar -xzf eksctl_Linux_${BUILDARCH}.tar.gz -C /tmp && \
    rm eksctl_Linux_${BUILDARCH}.tar.gz &&\
    mv /tmp/eksctl /usr/local/bin

### Cloudformation tools - Install using uv
RUN uv pip install cfn-lint pyyaml checkov==${CHECKOV_VERSION} && \
    curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/aws-cloudformation/cloudformation-guard/main/install-guard.sh | sh && \
    cp /root/.guard/3/cfn-guard-v3-*-ubuntu-latest/cfn-guard /usr/local/bin/cfn-guard && \
    cfn-guard --version

### SAM CLI
RUN wget https://github.com/aws/aws-sam-cli/releases/download/${SAM_VERSION}/aws-sam-cli-linux-${SAMCLIARCH}.zip && \
    unzip -q aws-sam-cli-linux-${SAMCLIARCH}.zip -d sam-installation && \
    ./sam-installation/install > /dev/null && \
    rm -rf aws-sam-cli-linux-${SAMCLIARCH}.zip sam-installation && \
    sam --version

### act
RUN curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | bash && \
    mv bin/act /usr/local/bin/act && \
    act --version

### GitHub CLI (gh)
RUN curl -Lo /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_${BUILDARCH}.tar.gz" && \
    tar -xzf /tmp/gh.tar.gz -C /tmp && \
    mv /tmp/gh_${GH_VERSION#v}_linux_${BUILDARCH}/bin/gh /usr/local/bin/gh && \
    rm -rf /tmp/gh.tar.gz /tmp/gh_*/ && \
    gh --version

### yq (YAML processor)
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${BUILDARCH} && \
    chmod +x /usr/local/bin/yq && \
    yq --version

### Copy configuration files
COPY config/ruff.toml /etc/ruff.toml
COPY config/mypy.ini /etc/mypy.ini
COPY config/pytest.ini /etc/pytest.ini

### rootlessコンテナ devuserでの実行
RUN /usr/sbin/groupadd -g 1000 devgroup && \
    /usr/sbin/useradd -u 1000 -g 1000 -m devuser && \
    mkdir /work && \
    chown devuser:devgroup /work && \
    chown -R devuser:devgroup /opt/pyenv && \
    echo "devuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -aG wheel devuser

# Setup Python and development tools for devuser
USER devuser

# Configure basic aliases for devuser
RUN echo 'alias ll="ls -la"' >> /home/devuser/.bashrc && \
    echo 'alias python="python3"' >> /home/devuser/.bashrc && \
    # Create config directories and link system configs
    mkdir -p /home/devuser/.config/ruff && \
    mkdir -p /home/devuser/.config/mypy && \
    mkdir -p /home/devuser/.config/pytest && \
    ln -s /etc/ruff.toml /home/devuser/.config/ruff/ruff.toml && \
    ln -s /etc/mypy.ini /home/devuser/.config/mypy/config && \
    ln -s /etc/pytest.ini /home/devuser/.config/pytest/pytest.ini


VOLUME /work
WORKDIR /work

ENTRYPOINT ["tail", "-f", "/dev/null"]
