### BASE
FROM almalinux:9.3-minimal
    #https://repo.almalinux.org/almalinux/9/isos/x86_64/

### ENV
ENV TERRAFORM_VERSION=1.7.4
    #https://releases.hashicorp.com/terraform/
ENV ANSIBLE_VERSION=8.7.0
    #ansible core 2.15
    #https://docs.ansible.com/ansible/latest/roadmap/ansible_roadmap_index.html
ENV DOCKERCLI_VERSION=1:25.0.3-1.el9
    #https://download.docker.com/linux/centos/9/x86_64/stable/Packages/
ENV KUBECTL_VERSION=v1.29.1
    #https://dl.k8s.io/release/stable.txt
    #https://github.com/kubernetes/kubectl/tags
ENV ECSCLI_VERSION=v1.21.0
    #https://github.com/aws/amazon-ecs-cli
ENV EKSCTL_VESION=v0.171.0
    #https://github.com/eksctl-io/eksctl

### ARG
ARG BUILDARCH

### tools
RUN microdnf update -y && \
    microdnf install -y epel-release yum-utils wget sudo which tar zip unzip gzip bind-utils iputils pip git && \
    rm -rf /var/cahce/yum/* && \
    microdnf clean all

#### TimeZone & LANG
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    microdnf install -y glibc-locale-source && \
    localedef -f UTF-8 -i ja_JP ja_JP.UTF-8 && \
    rm -rf /var/cahce/yum/* && \
    microdnf clean all
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8" \
    TZ="Asia/Tokyo"

### Terraform
RUN curl -OL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip -d /usr/local/bin && \
    rm terraform_${TERRAFORM_VERSION}_linux_${BUILDARCH}.zip

### Ansible
RUN python -m pip install ansible==${ANSIBLE_VERSION} && \
    /bin/rm -rf /usr/local/lib/python3.9/site-packages/ansible_collections/fortinet 

### Docker/Kubernetes
RUN yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    microdnf -y install dnf-plugins-core docker-ce-cli-${DOCKERCLI_VERSION} && \
    curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${BUILDARCH}/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh && \
    rm ./get_helm.sh && \
    rm -rf /var/cahce/yum/* && \
    microdnf clean all

### cloud
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm awscliv2.zip && \
    rm -rf ./aws && \
    sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-${ECSCLI_VERSION} && \
    sudo chmod +x /usr/local/bin/ecs-cli && \
    curl -sLO "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VESION}/eksctl_Linux_${BUILDARCH}.tar.gz" && \
    tar -xzf eksctl_Linux_${BUILDARCH}.tar.gz -C /tmp && \
    rm eksctl_Linux_${BUILDARCH}.tar.gz &&\
    mv /tmp/eksctl /usr/local/bin

#rootlessコンテナ toshikazuでの実行
RUN /usr/sbin/useradd devuser && \
    mkdir /work && \
    chown devuser:devuser /work && \
    echo "devuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER devuser
VOLUME /work
WORKDIR /work

ENTRYPOINT ["tail", "-f", "/dev/null"]