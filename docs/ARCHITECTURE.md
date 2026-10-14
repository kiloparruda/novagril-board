# Arquitetura — Novagril Board

## Objetivo

Aplicação interna e colaborativa para o board definir, posicionar, votar e priorizar projetos estratégicos da Novagril.

A interface mantém o POC visual já aprovado: dashboard único, gráfico anelar, quatro níveis de prioridade, departamentos no anel exterior, atividade recente, consenso e resumo por voz.

## Autenticação

Dois métodos suportados:

1. **Microsoft 365 SSO** através de Microsoft Entra ID.
2. **PIN temporário** enviado por email para membros convidados.

A autenticação e as permissões são sempre validadas no servidor.

## Regra crítica de autoria

Um projeto possui um `created_by_user_id` imutável.

- Qualquer membro ativo do board pode consultar e votar.
- Apenas o criador pode alterar departamento, prioridade ou posição do seu projeto.
- O frontend pode ocultar ou bloquear a interação, mas o servidor repete sempre a validação.

## Mapa estratégico

Prioridade, do centro para fora:

1. Máxima
2. Alta
3. Média
4. Baixa

O projeto guarda também uma posição/ordem dentro do respetivo setor para permitir reposicionamento visual sem perder departamento ou prioridade.

## Base de dados

A aplicação deverá reutilizar a base de dados já disponível no hosting Novagril.

A primeira migração preparada neste repositório assume **SQL Server**, coerente com o ecossistema ASP.NET/MSSQL usado no hosting atual. Se a base concreta disponível for MySQL/MariaDB, a camada de persistência será adaptada sem alterar o modelo funcional.

As credenciais nunca entram no GitHub. Ficam apenas nas variáveis de ambiente do servidor.

## Entidades principais

- users
- invitations
- auth_pins
- sessions
- departments
- projects
- votes
- comments
- activities

## Convites

O administrador cria um convite com nome e email. O membro recebe um link e pode:
- autenticar-se com Microsoft 365; ou
- pedir um PIN temporário.

## Próxima etapa técnica

1. Confirmar motor e dados de ligação da BD existente.
2. Aplicar `database/sqlserver/schema.sql`.
3. Substituir a persistência local do POC pela API central.
4. Registar a app no Microsoft Entra ID.
5. Configurar SMTP/Graph para convites e PIN.
6. Publicar o backend e ligar o HTML ao endpoint da API.
