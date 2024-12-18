INSTALL-DEBIAN-PACK.md

# Instalação do Docker PS Call no Debian/Ubuntu

O **Docker PS Call** está disponível como um pacote `.deb` para fácil instalação em sistemas Debian-based (Ubuntu, Debian, etc). Siga os passos abaixo para instalar e configurar o script.

---

## **1. Baixar o Pacote**

Baixe o pacote `.deb` diretamente do repositório:

[Baixar docker-ps-call.deb](https://github.com/Machado-tec/docker-ps-call/blob/main/docker-ps-call.deb)

Ou use o **wget** no terminal:

```bash
wget https://github.com/Machado-tec/docker-ps-call/blob/main/docker-ps-call.deb -O docker-ps-call.deb

2. Instalar o Pacote

Instale o pacote com o comando dpkg:

sudo dpkg -i docker-ps-call.deb

Se houver erros de dependências, corrija automaticamente com:

sudo apt-get install -f

3. Verificar Instalação

Após a instalação, o script será instalado em /usr/local/bin. Verifique com:

ls -l /usr/local/bin/docker-ps-call

4. Executar o Script

Após a instalação, você pode executar o script diretamente de qualquer lugar no terminal:

docker-ps-call

Funcionamento do Script

Menu Principal

O script exibirá um menu com a lista de containers Docker em execução:

Selecione o container:
1. container_web    abc1234567
2. container_db     def8901234
3. container_cache  ghi5678901

Menu de Ações

Após selecionar um container, um sub-menu será exibido:

Ações para o container: container_web
1. Executar (bash)
2. Listar (logs)
3. Reiniciar (confirmar)

Reiniciar (Confirmar)

Ao selecionar a opção de reiniciar, uma tela de confirmação será exibida:

Tem certeza que deseja reiniciar o container container_web?
[ Yes ]  [ No ]

Teclas de Controle
	•	Esc: Voltar ao menu anterior ou sair do script.
	•	Ctrl+C: Força a saída do script.

Atualizar o Script

Caso uma nova versão seja disponibilizada, basta baixar e instalar novamente o pacote .deb:

wget https://github.com/Machado-tec/docker-ps-call/blob/main/docker-ps-call.deb -O docker-ps-call.deb
sudo dpkg -i docker-ps-call.deb

Desinstalação

Para remover o Docker PS Call, execute:

sudo apt remove docker-ps-call

Pronto!

Agora você pode utilizar o Docker PS Call de forma simples e eficiente para gerenciar containers Docker no terminal. 🚀

---

### **O que foi feito:**
1. Instruções claras para **baixar**, **instalar**, e **executar** o pacote `.deb`.
2. Explicação do funcionamento do script.
3. Adicionada seção para atualização e desinstalação.

Se precisar de mais alguma coisa, é só avisar! 🚀