# Novagril Board

POC colaborativo para definição e priorização da estratégia digital da Novagril Liscampo.

## Estado
- Repositório ligado ao POC aprovado nesta conversa.
- Dashboard único, sem navegação por menus.
- Mapa estratégico anelar com 10 departamentos e 4 níveis de prioridade.
- Apenas o criador de um projeto pode reposicioná-lo.
- Votação e consenso disponíveis aos membros do board.
- Autenticação prevista por PIN temporário ou Microsoft 365 SSO.
- Base de dados: usar a base de dados já existente no hosting Novagril; credenciais ficam exclusivamente em variáveis de ambiente.

## Prioridades
Da zona central para o exterior:
1. Prioridade Máxima
2. Alta
3. Média
4. Baixa

## Departamentos iniciais
Vendas, Técnica, Logística, Calisflor, Academia, Administração, Financeira e Administrativa, Contabilidade, Retalho e RH.

## Segurança
Nunca colocar credenciais, connection strings, segredos Microsoft ou SMTP no GitHub. Usar variáveis de ambiente no servidor.

## Próximo passo
Ligar a aplicação à base de dados do hosting e substituir a persistência local do POC por persistência central, mantendo validação server-side da autoria dos projetos.
