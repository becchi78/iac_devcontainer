### BASE
FROM almalinux:9.6-minimal
    #https://repo.almalinux.org/almalinux/9/isos/x86_64/

### ENV
ENV TERRAFORM_VERSION=1.7.4 \
    #https://releases.hashicorp.com/terraform/
    ANSIBLE_VERSION=8.7.0 \
    #ansible core 2.15
    #https://docs.ansible.com/ansible/latest/roadmap/ansible_roadmap_index.html
    DOCKERCLI_VERSION=1:25.0.3-1.el9 \
    #https://download.docker.com/linux/centos/9/x86_64/stable/Packages/
    KUBECTL_VERSION=v1.29.1 \
    #https://dl.k8s.io/release/stable.txt
    #https://github.com/kubernetes/kubectl/tags
    AWSCLI_VERSION=2.17.49 \
    #https://github.com/aws/aws-cli
    SAM_VERSION=v1.123.0 \
    #https://github.com/aws/aws-sam-cli
    ECSCLI_VERSION=v1.21.0 \
    #https://github.com/aws/amazon-ecs-cli
    EKSCTL_VERSION=v0.171.0 \
    #https://github.com/eksctl-io/eksctl
    PYTHON_VERSION=3.12 \
    #Python version for uv
    NODE_VERSION=22 \
    #for Claude Code CLI
    UV_VERSION=0.8.19 \
    #https://github.com/astral-sh/uv
    RUFF_VERSION=0.8.4
    #https://github.com/astral-sh/ruff

### ARG
ARG BUILDARCH
ARG AWSCLIARCH
ARG SAMCLIARCH

### tools (gcc等のビルドツールを除外)
RUN microdnf update -y && \
    microdnf install -y epel-release yum-utils wget sudo which tar zip unzip gzip bind-utils iputils git jq tree vi diffutils glibc-locale-source && \
    microdnf clean all && \
    rm -rf /var/cache/yum/* && \
    rm -rf /tmp/*

### TimeZone & LANG
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    localedef -f UTF-8 -i ja_JP ja_JP.UTF-8

### Install uv and Python 3.12
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    uv --version && \
    # Install Python 3.12 using uv
    uv python install 3.12 && \
    uv python pin 3.12 && \
    # Create symlinks for system-wide access
    ln -sf /root/.local/share/uv/python/cpython-3.12.*/bin/python3.12 /usr/local/bin/python3.12 && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python && \
    python --version

### Python Development Environment Setup
# Install Ruff (Python linter and formatter)
RUN uv tool install ruff==${RUFF_VERSION} && \
    ln -sf /root/.local/share/uv/tools/ruff/bin/ruff /usr/local/bin/ruff && \
    ruff --version

# Install Python development tools using uv
RUN uv pip install --system \
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

### Node.js 22 and Claude Code CLI
RUN curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | sudo bash - && \
    microdnf install -y nodejs && \
    npm install -g @anthropic-ai/claude-code && \
    claude-code --version && \
    microdnf clean all

### Terraform
RUN curl -OL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip -d /usr/local/bin && \
    rm terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip && \
    curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash && \
    tflint --version

### Ansible - Install using uv
RUN uv pip install --system ansible==${ANSIBLE_VERSION} && \
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
    unzip awscliv2.zip && \
    ./aws/install && \
    rm awscliv2.zip && \
    rm -rf ./aws

RUN sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-${BUILDARCH}-${ECSCLI_VERSION} && \
    sudo chmod +x /usr/local/bin/ecs-cli

RUN curl -sLO "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_${BUILDARCH}.tar.gz" && \
    tar -xzf eksctl_Linux_${BUILDARCH}.tar.gz -C /tmp && \
    rm eksctl_Linux_${BUILDARCH}.tar.gz &&\
    mv /tmp/eksctl /usr/local/bin

### Cloudformation tools - Install using uv
RUN uv pip install --system cfn-lint pyyaml && \
    curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/aws-cloudformation/cloudformation-guard/main/install-guard.sh | sh && \
    cp /root/.guard/3/cfn-guard-v3-*-ubuntu-latest/cfn-guard /usr/local/bin/cfn-guard && \
    cfn-guard --version

### SAM CLI
RUN wget https://github.com/aws/aws-sam-cli/releases/download/${SAM_VERSION}/aws-sam-cli-linux-${SAMCLIARCH}.zip && \
    unzip aws-sam-cli-linux-${SAMCLIARCH}.zip -d sam-installation && \
    sudo ./sam-installation/install && \
    rm -rf aws-sam-cli-linux-${SAMCLIARCH}.zip sam-installation && \
    sam --version

### act
RUN curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash && \
    mv bin/act /usr/local/bin/act && \
    act --version

### yq (YAML processor)
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${BUILDARCH} && \
    chmod +x /usr/local/bin/yq && \
    yq --version

### Copy configuration files
COPY config/ruff.toml /etc/ruff.toml
COPY config/mypy.ini /etc/mypy.ini
COPY config/pytest.ini /etc/pytest.ini

### rootlessコンテナ devuserでの実行
RUN /usr/sbin/groupadd -r devgroup && \
    /usr/sbin/useradd -r -g devgroup -m devuser && \
    mkdir /work && \
    chown devuser:devgroup /work && \
    echo "devuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup Python and development tools for devuser
USER devuser

# Configure environment and tools for devuser
RUN echo 'export PATH="/home/devuser/.local/bin:$PATH"' >> /home/devuser/.bashrc && \
    echo 'alias ll="ls -la"' >> /home/devuser/.bashrc && \
    echo 'alias python="python3"' >> /home/devuser/.bashrc && \
    # Configure git
    git config --global init.defaultBranch main && \
    git config --global color.ui auto && \
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
