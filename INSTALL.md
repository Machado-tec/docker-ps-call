---

### **INSTALL.md**
```markdown
# Instalação do Docker PS Call

O **Docker PS Call** é um script interativo em Bash que facilita a execução de ações em containers Docker. Este guia descreve o processo de instalação e configuração.

---

## **Pré-requisitos**

1. **Docker**: O Docker deve estar instalado e configurado no seu sistema.
2. **Dialog**: Ferramenta para menus interativos no terminal.

---

## **1. Instalação do Docker**

Caso o Docker ainda não esteja instalado, execute os comandos abaixo:

```bash
# Atualize a lista de pacotes
sudo apt update

# Instale o Docker
sudo apt install docker.io -y

# Verifique a instalação
sudo docker --version
```

---

## **2. Instalação do Dialog**

O **dialog** é utilizado para criar os menus no terminal. Instale com:

```bash
sudo apt install dialog -y
```

---

## **3. Clonar o Repositório**

Clone o repositório **docker-ps-call** em um diretório local:

```bash
git clone git@github.com:Machado-tec/docker-ps-call.git
cd docker-ps-call
```

---

## **4. Tornar o Script Executável**

Dê permissão de execução ao script principal:

```bash
chmod +x docker-ps-call.sh
```

---

## **5. Executar o Script**

Para executar o script, basta rodar:

```bash
./docker-ps-call.sh
```

---

## **6. Pronto!**

O script está configurado e pronto para uso. Ele exibirá um menu interativo com os containers ativos, permitindo que você:

1. Execute um **bash** no container.
2. Visualize **logs** em tempo real.
3. Reinicie o container com confirmação.

---

## **Dicas**

- Utilize **Esc** para voltar nos menus ou sair do script.
- Utilize **Ctrl+C** para forçar a saída a qualquer momento.

---

## **Problemas Comuns**

- **Docker não instalado**: Verifique se o Docker foi instalado corretamente com `sudo docker --version`.
- **Permissão negada**: Execute o script com permissões de superusuário (`sudo ./docker-ps-call.sh`).

---

## **Atualizações**

Para atualizar o script para a versão mais recente, basta acessar o repositório e executar:

```bash
git pull origin main
```

---

## **Pronto!**

Você instalou e configurou o Docker PS Call com sucesso. Agora, basta executá-lo sempre que precisar gerenciar seus containers Docker.
```

---
\