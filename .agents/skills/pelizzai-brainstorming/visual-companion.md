# Guia do Companheiro Visual

Companheiro visual de brainstorming baseado no navegador para mostrar mockups, diagramas e opções.

## Quando Usar

Decida por pergunta, não por sessão. O teste é: **o usuário entenderia melhor vendo do que lendo?**

**Use o navegador** quando o conteúdo em si for visual:

- **Mockups de UI** — wireframes, layouts, estruturas de navegação, designs de componentes
- **Diagramas de arquitetura** — componentes do sistema, fluxo de dados, mapas de relacionamento
- **Comparações visuais lado a lado** — comparação entre dois layouts, dois esquemas de cores, duas direções de design
- **Polimento de design** — quando a pergunta é sobre aparência, espaçamento, hierarquia visual
- **Relações espaciais** — máquinas de estado, fluxogramas, relações entre entidades renderizadas como diagramas

**Use o terminal** quando o conteúdo for textual ou tabular:

- **Perguntas de requisitos e escopo** — "o que X significa?", "quais funcionalidades estão no escopo?"
- **Escolhas conceituais A/B/C** — escolher entre abordagens descritas em palavras
- **Listas de tradeoffs** — prós/contras, tabelas comparativas
- **Decisões técnicas** — design de API, modelagem de dados, seleção de abordagem arquitetural
- **Perguntas de esclarecimento** — qualquer coisa em que a resposta seja palavras, não uma preferência visual

Uma pergunta _sobre_ um tema de UI não é automaticamente uma pergunta visual. "Que tipo de wizard você quer?" é conceitual — use o terminal. "Qual destes layouts de wizard parece certo?" é visual — use o navegador.

## Como Funciona

O servidor observa um diretório em busca de arquivos HTML e serve o mais recente ao navegador. Você escreve conteúdo HTML em `screen_dir`; o usuário vê esse conteúdo no navegador e pode clicar para selecionar opções. As seleções são registradas em `state_dir/events`, que você lê no próximo turno.

**Fragmentos de conteúdo vs documentos completos:** Se seu arquivo HTML começar com `<!DOCTYPE` ou `<html`, o servidor o serve como está (apenas injeta o script auxiliar). Caso contrário, o servidor envolve automaticamente seu conteúdo no template de moldura — adicionando cabeçalho, tema CSS, status de conexão e toda a infraestrutura interativa. **Escreva fragmentos de conteúdo por padrão.** Escreva documentos completos apenas quando precisar de controle total sobre a página.

## Iniciando uma Sessão

```bash
# Inicie DEPOIS que o usuário aprovar o companion. --open abre automaticamente
# o navegador na primeira tela; --project-dir persiste mockups e permite
# reiniciar na mesma porta.
scripts/start-server.sh --project-dir /path/to/project --open

# Retorna: {"type":"server-started","port":52341,
#           "url":"http://localhost:52341/?key=ab12…",
#           "screen_dir":"/path/to/project/.pelizzai/brainstorm/12345-1706000000/content",
#           "state_dir":"/path/to/project/.pelizzai/brainstorm/12345-1706000000/state"}
```

Salve `screen_dir` e `state_dir` da resposta. Com `--open`, o navegador se abre sozinho quando você envia a primeira tela — você não precisa pedir ao usuário para abri-lo, mas ainda assim compartilhe a URL como fallback (ambientes headless/remotos podem não abrir automaticamente).

**A URL contém uma chave de sessão (`?key=…`).** O servidor rejeita qualquer requisição sem ela, então sempre dê ao usuário a URL **completa** do campo `url` — nunca remova a query string e nunca entregue apenas `http://host:port`. A chave controla o acesso HTTP e WebSocket, de modo que uma aba perdida do navegador ou outra máquina na rede não consiga ler as telas nem injetar eventos. Depois do primeiro carregamento, o navegador lembra a chave por meio de um cookie, então recarregamentos e assets de `/files/*` funcionam sem repeti-la.

**Encontrando informações de conexão:** O servidor grava seu JSON de inicialização em `$STATE_DIR/server-info`. Se você iniciou o servidor em segundo plano e não capturou stdout, leia esse arquivo para obter a URL e a porta. Ao usar `--project-dir`, verifique `<project>/.pelizzai/brainstorm/` para encontrar o diretório da sessão.

**Observação:** Passe a raiz do projeto como `--project-dir` para que os mockups persistam em `.pelizzai/brainstorm/` e sobrevivam a reinicializações do servidor. Sem isso, os arquivos vão para `/tmp` e são limpos. Lembre o usuário de adicionar `.pelizzai/` ao `.gitignore` se ainda não estiver lá.

**Iniciando o servidor por plataforma:**

**Claude Code:**

```bash
# O modo padrão funciona — o script coloca o servidor em segundo plano sozinho.
scripts/start-server.sh --project-dir /path/to/project --open
```

No Windows, o script detecta automaticamente e alterna para o modo foreground (que bloqueia a chamada da ferramenta). Use `run_in_background: true` na chamada da ferramenta Bash para que o servidor sobreviva entre turnos da conversa; então leia `$STATE_DIR/server-info` no próximo turno para obter a URL e a porta.

**Codex:**

```bash
# O Codex encerra processos em segundo plano. O script detecta CODEX_CI
# automaticamente e alterna para o modo foreground. Execute normalmente —
# nenhuma flag extra é necessária.
scripts/start-server.sh --project-dir /path/to/project --open
```

**Gemini CLI:**

```bash
# Use --foreground e defina is_background: true na chamada da ferramenta shell
# para que o processo sobreviva entre turnos
scripts/start-server.sh --project-dir /path/to/project --open --foreground
```

**Copilot CLI:**

```bash
# Use --foreground e inicie o servidor via ferramenta bash com mode: "async"
# para que o processo sobreviva entre turnos. Capture o shellId retornado para
# read_bash / stop_bash se precisar interagir com ele depois.
scripts/start-server.sh --project-dir /path/to/project --open --foreground
```

**Outros ambientes:** O servidor precisa continuar rodando em segundo plano entre turnos da conversa. Se seu ambiente encerra processos destacados, use `--foreground` e execute o comando com o mecanismo de execução em segundo plano da sua plataforma.

Se a URL estiver inacessível pelo navegador (comum em ambientes remotos/containerizados), vincule a um host que não seja loopback:

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

Use `--url-host` para controlar qual hostname é impresso no JSON da URL retornada.

## O Loop

1. **Verifique se o servidor está ativo** e então **escreva HTML** em um novo arquivo dentro de `screen_dir`:
    - **Obrigatório: confirme que o servidor está ativo antes de mencionar a URL ou enviar uma tela.** Verifique que `$STATE_DIR/server-info` existe e que `$STATE_DIR/server-stopped` não existe. Se ele tiver sido encerrado, reinicie-o com `start-server.sh` usando o **mesmo `--project-dir`** — ele reutiliza a mesma porta, então a aba aberta do usuário reconecta sozinha (ela mostra uma sobreposição de "pausado" enquanto o servidor está fora do ar) e você não precisa enviar uma nova URL. O servidor encerra automaticamente após 4 horas ocioso (configurável com `--idle-timeout-minutes`).
    - Use nomes de arquivo semânticos: `platform.html`, `visual-style.html`, `layout.html`
    - **Nunca reutilize nomes de arquivo** — cada tela recebe um arquivo novo
    - Use sua ferramenta de criação de arquivos — **nunca use cat/heredoc** (isso despeja ruído no terminal)
    - O servidor serve automaticamente o arquivo mais recente

2. **Diga ao usuário o que esperar e encerre seu turno:**
    - Lembre-o da URL (em cada etapa, não apenas na primeira)
    - Dê um breve resumo textual do que está na tela (por exemplo, "Mostrando 3 opções de layout para a homepage")
    - Peça que ele responda no terminal: "Dê uma olhada e me diga o que achou. Clique para selecionar uma opção se quiser."

3. **No próximo turno** — depois que o usuário responder no terminal:
    - Leia `$STATE_DIR/events` se existir — ele contém as interações do usuário no navegador (cliques, seleções) como linhas JSON
    - Combine isso com o texto do usuário no terminal para obter o quadro completo
    - A mensagem no terminal é o feedback principal; `state_dir/events` fornece dados estruturados de interação

4. **Itere ou avance** — se o feedback mudar a tela atual, escreva um novo arquivo (por exemplo, `layout-v2.html`). Avance para a próxima pergunta apenas quando a etapa atual estiver validada.

5. **Descarregue ao voltar para o terminal** — quando a próxima etapa não precisar do navegador (por exemplo, uma pergunta de esclarecimento, uma discussão de tradeoffs), envie uma tela de espera para limpar o conteúdo antigo:

    ```html
    <!-- filename: waiting.html (ou waiting-2.html, etc.) -->
    <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
    	<p class="subtitle">Continuando no terminal...</p>
    </div>
    ```

    Isso evita que o usuário fique olhando para uma escolha já resolvida enquanto a conversa avançou. Quando a próxima pergunta visual surgir, envie um novo arquivo de conteúdo como de costume.

6. Repita até terminar.

## Escrevendo Fragmentos de Conteúdo

Escreva apenas o conteúdo que entra dentro da página. O servidor o envolve automaticamente no template de moldura (cabeçalho, CSS do tema, status de conexão e toda a infraestrutura interativa).

**Exemplo mínimo:**

```html
<h2>Qual layout funciona melhor?</h2>
<p class="subtitle">Considere legibilidade e hierarquia visual</p>

<div class="options">
	<div class="option" data-choice="a" onclick="toggleSelect(this)">
		<div class="letter">A</div>
		<div class="content">
			<h3>Coluna única</h3>
			<p>Experiência de leitura limpa e focada</p>
		</div>
	</div>
	<div class="option" data-choice="b" onclick="toggleSelect(this)">
		<div class="letter">B</div>
		<div class="content">
			<h3>Duas colunas</h3>
			<p>Navegação lateral com conteúdo principal</p>
		</div>
	</div>
</div>
```

É só isso. Não precisa de `<html>`, CSS nem tags `<script>`. O servidor fornece tudo isso.

## Classes CSS Disponíveis

O template de moldura fornece estas classes CSS para seu conteúdo:

### Opções (escolhas A/B/C)

```html
<div class="options">
	<div class="option" data-choice="a" onclick="toggleSelect(this)">
		<div class="letter">A</div>
		<div class="content">
			<h3>Título</h3>
			<p>Descrição</p>
		</div>
	</div>
</div>
```

**Seleção múltipla:** Adicione `data-multiselect` ao contêiner para permitir que usuários selecionem várias opções. Cada clique alterna o estilo selecionado do item.

```html
<div class="options" data-multiselect>
	<!-- mesma marcação de opção — usuários podem selecionar/desselecionar várias -->
</div>
```

### Cards (designs visuais)

```html
<div class="cards">
	<div class="card" data-choice="design1" onclick="toggleSelect(this)">
		<div class="card-image"><!-- conteúdo do mockup --></div>
		<div class="card-body">
			<h3>Nome</h3>
			<p>Descrição</p>
		</div>
	</div>
</div>
```

### Contêiner de mockup

```html
<div class="mockup">
	<div class="mockup-header">Prévia: Layout do Dashboard</div>
	<div class="mockup-body"><!-- seu HTML de mockup --></div>
</div>
```

### Visão dividida (lado a lado)

```html
<div class="split">
	<div class="mockup"><!-- esquerda --></div>
	<div class="mockup"><!-- direita --></div>
</div>
```

### Prós/Contras

```html
<div class="pros-cons">
	<div class="pros">
		<h4>Prós</h4>
		<ul>
			<li>Benefício</li>
		</ul>
	</div>
	<div class="cons">
		<h4>Contras</h4>
		<ul>
			<li>Desvantagem</li>
		</ul>
	</div>
</div>
```

### Elementos de mockup (blocos de wireframe)

```html
<div class="mock-nav">Logo | Início | Sobre | Contato</div>
<div style="display: flex;">
	<div class="mock-sidebar">Navegação</div>
	<div class="mock-content">Área de conteúdo principal</div>
</div>
<button class="mock-button">Botão de ação</button>
<input class="mock-input" placeholder="Campo de entrada" />
<div class="placeholder">Área de placeholder</div>
```

### Tipografia e seções

- `h2` — título da página
- `h3` — título de seção
- `.subtitle` — texto secundário abaixo do título
- `.section` — bloco de conteúdo com margem inferior
- `.label` — texto de rótulo pequeno em maiúsculas

## Formato dos Eventos do Navegador

Quando o usuário clica em opções no navegador, suas interações são registradas em `$STATE_DIR/events` (um objeto JSON por linha). O arquivo é limpo automaticamente quando você envia uma nova tela.

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Complex Grid","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

O fluxo completo de eventos mostra o caminho de exploração do usuário — ele pode clicar em várias opções antes de decidir. O último evento `choice` costuma ser a seleção final, mas o padrão de cliques pode revelar hesitação ou preferências sobre as quais vale perguntar.

Se `$STATE_DIR/events` não existir, o usuário não interagiu com o navegador — use apenas o texto dele no terminal.

## Dicas de Design

- **Ajuste a fidelidade à pergunta** — wireframes para layout, polimento para perguntas de polimento
- **Explique a pergunta em cada página** — "Qual layout parece mais profissional?", não apenas "Escolha um"
- **Itere antes de avançar** — se o feedback mudar a tela atual, escreva uma nova versão
- **Máximo de 2 a 4 opções** por tela
- **Use conteúdo real quando importar** — para um portfólio de fotografia, use imagens reais (Unsplash). Conteúdo placeholder oculta problemas de design.
- **Mantenha mockups simples** — foque em layout e estrutura, não em design pixel-perfect

## Nomeação de Arquivos

- Use nomes semânticos: `platform.html`, `visual-style.html`, `layout.html`
- Nunca reutilize nomes de arquivo — cada tela deve ser um novo arquivo
- Para iterações: acrescente um sufixo de versão como `layout-v2.html`, `layout-v3.html`
- O servidor serve o arquivo mais recente por horário de modificação

## Limpeza

```bash
scripts/stop-server.sh $SESSION_DIR
```

Se a sessão usou `--project-dir`, os arquivos de mockup persistem em `.pelizzai/brainstorm/` para referência posterior. Apenas sessões em `/tmp` são excluídas ao parar.

## Referência

- Template de moldura (referência de CSS): `scripts/frame-template.html`
- Script auxiliar (client-side): `scripts/helper.js`
