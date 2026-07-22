# Sinais de Escrita por IA

[![A screenshot of ChatGPT reading: "[header] Legacy & Interpretation [body] The "Black Hole Edition" is not just a meme — it's a celebration of grassroots car culture, where ideas are limitless and fun is more important than spec sheets. Whether powered by a rotary engine, a V8 swap, or an imagined fighter jet turbine, the Miata remains the canvas for car enthusiasts worldwide."](https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/ChatGPT_response_screenshot_1.jpg/250px-ChatGPT_response_screenshot_1.jpg)](https://en.wikipedia.org/wiki/File:ChatGPT_response_screenshot_1.jpg)

_Os LLMs tendem a ter um estilo de escrita identificável._

Esta é uma lista de convenções de escrita e formatação típicas de [chatbots de IA](https://en.wikipedia.org/wiki/AI_chatbot 'AI chatbot') como o [ChatGPT](https://en.wikipedia.org/wiki/ChatGPT 'ChatGPT'), com exemplos reais retirados de artigos e rascunhos da Wikipédia. É um [guia de campo](https://en.wikipedia.org/wiki/Field_guide 'Field guide') para ajudar a detectar [conteúdo gerado por IA não declarado](https://en.wikipedia.org/wiki/Wikipedia:LLMDISCLOSE 'Wikipedia:LLMDISCLOSE') na Wikipédia. Esta lista é _descritiva_, não _prescritiva_; consiste em observações, não em regras. Orientações sobre formatação ou linguagem a evitar em artigos da Wikipédia podem ser encontradas nas [políticas e diretrizes](https://en.wikipedia.org/wiki/Wikipedia:PAG 'Wikipedia:PAG') e no [Manual de Estilo](https://en.wikipedia.org/wiki/Wikipedia:MOS 'Wikipedia:MOS'), mas não cabem nesta página.

Esta lista _não_ é uma proibição de certas palavras, frases ou sinais de pontuação. Nem todo texto que apresenta esses indicadores é gerado por IA, pois os [modelos de linguagem de grande porte](https://en.wikipedia.org/wiki/Large_language_model 'Large language model') que alimentam os chatbots de IA são treinados em escrita humana, incluindo a escrita dos editores da Wikipédia. Este é simplesmente um catálogo de padrões muito comuns observados ao longo de muitos milhares de instâncias de texto gerado por IA, _específico da Wikipédia._ Embora parte de seus conselhos possa ser amplamente aplicável, alguns sinais — particularmente os que envolvem pontuação e formatação — podem não se aplicar em um contexto fora da Wikipédia.

Os padrões aqui também são apenas _sinais_ potenciais de um problema, não _o problema em si_. Embora muitas dessas questões sejam imediatamente óbvias e fáceis de corrigir — por exemplo, negrito excessivo, uso inadequado de linguagem e pontuação, marcação quebrada, peculiaridades no estilo de citação —, elas podem apontar para problemas menos visíveis externamente que acarretam [riscos muito mais sérios em relação às políticas](https://en.wikipedia.org/wiki/Wikipedia:AIFAIL 'Wikipedia:AIFAIL'). Se o texto gerado por LLM for polido o suficiente (inicialmente ou posteriormente), esses defeitos de superfície podem não estar presentes, mas problemas mais profundos podem estar. Por favor, não trate esses sinais meramente como os problemas a serem corrigidos; isso poderia apenas dificultar a detecção. Os problemas reais são essas preocupações mais profundas, então certifique-se de abordá-las, seja você mesmo ou sinalizando-as, conforme a orientação em [Wikipedia:Large language models §Handling suspected LLM-generated content](https://en.wikipedia.org/wiki/Wikipedia:Large_language_models#Handling_suspected_LLM-generated_content 'Wikipedia:Large language models') e [Wikipedia:WikiProject AI Cleanup/Guide](https://en.wikipedia.org/wiki/Wikipedia:WikiProject_AI_Cleanup/Guide 'Wikipedia:WikiProject AI Cleanup/Guide').

O critério [G15](https://en.wikipedia.org/wiki/Wikipedia:G15 'Wikipedia:G15') da [política de eliminação rápida](https://en.wikipedia.org/wiki/Wikipedia:Speedy_deletion 'Wikipedia:Speedy deletion') (páginas geradas por LLM sem revisão humana) limita-se às indicações mais objetivas e menos contestáveis de que o conteúdo da página foi gerado por um LLM. Há três desses indicadores, sendo o primeiro encontrado em [§Comunicação destinada ao usuário](#comunicação-destinada-ao-usuário) e os outros dois em [§Citações](#citações).

Não confie exclusivamente em ferramentas de [detecção de conteúdo de inteligência artificial](https://en.wikipedia.org/wiki/Artificial_intelligence_content_detection 'Artificial intelligence content detection') (como o [GPTZero](https://en.wikipedia.org/wiki/GPTZero 'GPTZero')) para avaliar se um texto foi gerado por LLM. Embora tenham desempenho melhor do que o acaso, essas ferramentas têm taxas de erro não triviais e não podem substituir o julgamento humano.[^1] Os detectores podem ser frágeis diante de múltiplos fatores, como modificações no texto (por exemplo, paráfrase e alterações de espaçamento) e o uso de modelos generativos não vistos durante o treinamento do detector.[^2] Da mesma forma, não confie demais em sua própria interpretação. Pesquisas mostram que pessoas que usam muito os LLMs conseguem determinar corretamente se um artigo foi gerado por IA cerca de 90% das vezes, o que significa que, se você é um usuário experiente de LLMs e marca 10 páginas como geradas por IA, provavelmente acusou falsamente um editor.[^3] Pessoas que não usam muito os LLMs pessoalmente se saem apenas um pouco melhor do que o acaso (em ambas as direções) na identificação de artigos gerados por IA.[^3]

---

## Regressão à Média

Os LLMs (e as [redes neurais artificiais](https://en.wikipedia.org/wiki/Artificial_neural_network 'Artificial neural network') em geral) usam algoritmos estatísticos para adivinhar (inferir) o que deve vir a seguir com base em um grande corpus de material de treinamento. Assim, eles tendem a [regredir à média](https://en.wikipedia.org/wiki/Regression_to_the_mean 'Regression to the mean'); ou seja, o resultado tende ao desfecho estatisticamente mais provável que se aplica à mais ampla variedade de casos. Isso pode ser, ao mesmo tempo, uma força e uma "pista" para detectar conteúdo gerado por IA.

Por exemplo, os LLMs costumam ser treinados em dados da internet nos quais pessoas famosas são geralmente descritas com linguagem positiva e de aparência importante. Consequentemente, o LLM tende a omitir fatos específicos, incomuns e cheios de nuance (que são estatisticamente raros) e substituí-los por descrições mais genéricas e positivas (que são estatisticamente comuns). Assim, o altamente específico "inventor do primeiro dispositivo de engate de trens" pode virar "um titã revolucionário da indústria". É como gritar cada vez mais alto que um retrato mostra uma pessoa singularmente importante, enquanto o próprio retrato desbota de uma fotografia nítida para um esboço genérico e borrado. O sujeito torna-se simultaneamente menos específico e mais exagerado.[^4]

Essa regressão estatística à média — um aplainamento de fatos específicos em afirmações genéricas que poderiam se aplicar igualmente a muitos tópicos — torna o conteúdo gerado por IA mais fácil de detectar.

### Ênfase indevida em simbolismo, legado e importância

**Palavras de atenção:** _stands/serves as_, _is a testament/reminder_, _plays a vital/significant/crucial/pivotal role_, _underscores/highlights its importance/significance_, _reflects broader_, _symbolizing its ongoing/enduring/lasting impact_, _key turning point_, _indelible mark_, _deeply rooted_, _profound heritage_, _steadfast dedication_...

A escrita de LLMs frequentemente infla a importância do assunto adicionando afirmações sobre como aspectos arbitrários do tópico representam ou contribuem para um tema mais amplo.[^5] Há um repertório distinto e facilmente identificável de maneiras pelas quais ela escreve essas afirmações.[^6]

> The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal moment in the evolution of regional statistics in Spain. [...]
>
> The founding of Idescat represented a significant shift toward regional statistical independence, enabling [Catalonia](https://en.wikipedia.org/wiki/Catalonia 'Catalonia') to develop a statistical system tailored to its unique socio-economic context. This initiative was part of a broader movement across Spain to decentralize administrative functions and enhance regional governance.

> Kumba has long been an important center for trade and agriculture. [...] The establishment of road networks connecting Kumba to other parts of the Southwest Region, such as Mamfe and Buea, helped solidify its role as a regional hub.

Os LLMs podem incluir essas afirmações até para os assuntos mais mundanos, como etimologia ou dados populacionais. Às vezes, acrescentam preâmbulos cautelosos reconhecendo que o assunto é relativamente sem importância ou de baixo perfil, antes de falar de sua importância mesmo assim.

**Exemplos**

> During the [Spanish colonial period](<https://en.wikipedia.org/wiki/Spanish_Colonial_Period_(Philippines)> 'Spanish Colonial Period (Philippines)'), the name _Bakunutan_ was hispanized to _Bacnotan_, a modification reflected in official documents preserved in the [National Archives](https://en.wikipedia.org/wiki/National_Archives_of_the_Philippines 'National Archives of the Philippines') in Manila. This etymology highlights the enduring legacy of the community's resistance and the transformative power of unity in shaping its identity.

> Though it saw only limited application, it contributes to the broader history of early aviation engineering and reflects the influence of French rotary designs on German manufacturers.

Ao falar de biologia (por exemplo, quando solicitados a discorrer sobre uma espécie animal ou vegetal), os LLMs tendem a enfatizar demais as conexões com o ecossistema ou o ambiente mais amplo, mesmo quando essas conexões são tênues ou genéricas. Os LLMs também tendem a insistir no estado de conservação da espécie e nos esforços de pesquisa e preservação, mesmo que o estado seja desconhecido e não exista nenhum esforço sério.

**Exemplos**

> It plays a role in the ecosystem and contributes to Hawaii's rich cultural heritage. [...] Preserving this endemic species is vital not only for ecological diversity but also for sustaining the cultural traditions connected to Hawaii's native flora.

> Currently, there is no specific conservation assessment for _Lethrinops lethrinus_ by the International Union for Conservation of Nature (IUCN). However, the general health of the Lake Malawi ecosystem is crucial for the survival of this and other endemic species. Factors such as overfishing, pollution, and habitat destruction could potentially impact their populations.

### Ênfase indevida em notabilidade, atribuição e cobertura da mídia

**Palavras de atenção:** _independent coverage_, _local/regional/national/[country name] media outlets_, _music/business/tech outlets_, _active social media presence_

Da mesma forma, os LLMs agem como se a melhor maneira de provar que um assunto é notável fosse martelar os leitores com alegações de notabilidade, muitas vezes listando fontes que cobriram o assunto. Podem ou não fornecer contexto adicional sobre o que essas fontes de fato disseram a respeito do assunto, e frequentemente atribuem de forma imprecisa suas próprias [análises superficiais](#análises-superficiais) à fonte. Isso é mais comum em textos de ferramentas de IA mais recentes (2025 ou posteriores).

Comunicados de imprensa escritos por humanos também citam recortes de notícias há décadas, claro, mas os LLMs especificamente instruídos a escrever um artigo da Wikipédia frequentemente repetem a formulação exata das [diretrizes da Wikipédia](https://en.wikipedia.org/wiki/Wikipedia:N 'Wikipedia:N'), como "independent coverage" (cobertura independente).

**Exemplos**

> She spoke about AI on CNN, and was featured in Vogue, Wired, Toronto Star, and other media. [...] Her insights have also been featured in _Wired_, _Refinery29_, and other prominent media outlets.

> Her views have been cited in _The New York Times_, _BBC_, _Financial Times_, and _The Hindu_.

> Its significance is documented in archived school event programs and regional press coverage, including the _Mesabi Daily News_, which regularly reviewed performances held there.

Na Wikipédia especificamente, os LLMs frequentemente enfatizam minuciosamente suas fontes no corpo do texto — mesmo para cobertura trivial, fatos incontroversos ou outras situações em que um editor humano da Wikipédia teria mais probabilidade de fornecer uma citação em linha ou nenhuma fonte.

**Exemplos**

> The restaurant has also been mentioned in [ABC News](<https://en.wikipedia.org/wiki/ABC_News_(Australia)> 'ABC News (Australia)') coverage relating to incidents in the surrounding precinct, underscoring its role as a well-known late-night venue in the city [of [Adelaide](https://en.wikipedia.org/wiki/Adelaide 'Adelaide')].

> In the United States, university-based incubators and accelerators have expanded alongside these centers; an official Library of Congress review found that 31.5% of SBA [[Small Business Administration](https://en.wikipedia.org/wiki/Small_Business_Administration 'Small Business Administration')] Growth Accelerator Fund Competition winners from 2014–2016 were university-based programs.

Em artigos sobre pessoas/entidades que usam redes sociais, os LLMs frequentemente observam que elas "maintain an active social media presence" (mantêm uma presença ativa nas redes sociais) ou algo semelhante. Essa formulação é particularmente idiossincrática do texto de IA e relativamente incomum na Wikipédia antes de ~2024.

> The mall maintains a strong digital presence, particularly on Instagram, where it actively shares the latest updates and events. Forum Kochi has consistently demonstrated excellence in digital promotions, with high-quality, engaging, and impactful video content playing a key role in its outreach.

### Análises superficiais

**Palavras de atenção:** _ensuring ..._, _highlighting ..._, _emphasizing ..._, _reflecting ..._, _underscoring ..._, _showcasing ..._, _aligns with..._, _contributing to..._

Os chatbots de IA tendem a inserir análises superficiais da informação, muitas vezes em relação à sua importância, reconhecimento ou impacto.[^7] Isso é frequentemente feito anexando uma oração com [particípio presente](https://en.wikipedia.org/wiki/Participle#Forms 'Participle') (terminação "-ing" em inglês) ao final das frases, às vezes com [atribuições vagas](#atribuições-vagas-de-opinião) a terceiros (veja abaixo).[^7][^5]

Embora [muitas dessas palavras sejam fortes indícios de IA por si sós](https://en.wikipedia.org/wiki/Wikipedia:AIWORDS 'Wikipedia:AIWORDS'),[^6][^8] um indício ainda mais forte é quando os sujeitos desses verbos são fatos, eventos ou outras coisas inanimadas. Uma pessoa, por exemplo, pode destacar ou enfatizar algo, mas um fato ou evento não pode. O ato de "destacar" ou "sublinhar" não é algo que esteja de fato acontecendo; é uma alegação de um narrador desencarnado sobre o que algo significa.[^5]

Tais comentários costumam ser [síntese](https://en.wikipedia.org/wiki/Wikipedia:SYNTH 'Wikipedia:SYNTH') e/ou opiniões não atribuídas na voz da Wikipédia (wikivoice). Chatbots mais recentes com [geração aumentada por recuperação](https://en.wikipedia.org/wiki/Retrieval-augmented_generation 'Retrieval-augmented generation') (por exemplo, um chatbot de IA capaz de pesquisar na web) podem anexar essas afirmações a [fontes nomeadas](#ênfase-indevida-em-notabilidade-atribuição-e-cobertura-da-mídia) — por exemplo, "Roger Ebert destacou a influência duradoura" — independentemente de essas fontes dizerem algo sequer próximo.

**Exemplos**

> Douera enjoys close proximity to the capital city, Algiers, further enhancing its significance as a dynamic hub of activity and culture.

> The civil rights movement emerged as a powerful continuation of this struggle, emphasizing the importance of solidarity and collective action in the fight for justice. This historical legacy has influenced contemporary African-American families, shaping their values, community structures, and approaches to political engagement. Economically, the enduring impacts of systemic inequality have led to both challenges and innovations within African-American communities, driving a commitment to empowerment and social change that echoes through generations.

> Its bilingual monument sign, with inscriptions in both English and Spanish, underscores its role in bringing together Latter-day Saints from the United States and Mexico.

> These citations, spanning more than six decades and appearing in recognized academic publications, illustrate Blois' lasting influence in computational linguistics, grammar, and neology.

> It holds a pivotal place in the [East Central Railway Zone](https://en.wikipedia.org/wiki/East_Central_Railway_Zone 'East Central Railway Zone') of [Indian Railways](https://en.wikipedia.org/wiki/Indian_Railways 'Indian Railways'), serving as a major railway hub with historical significance. The station has [1,676 mm](https://en.wikipedia.org/wiki/5_ft_6_in_gauge_railway '5 ft 6 in gauge railway') (5 ft 6 in) [broad gauge](https://en.wikipedia.org/wiki/Broad_gauge 'Broad gauge') along with 8 tracks and 6 platforms. [...] Historically, it has been crucial for linking [Darbhanga](https://en.wikipedia.org/wiki/Darbhanga 'Darbhanga') with significant cities like [Delhi](https://en.wikipedia.org/wiki/Delhi 'Delhi'), [Patna](https://en.wikipedia.org/wiki/Patna 'Patna'), and [Kolkata](https://en.wikipedia.org/wiki/Kolkata 'Kolkata'), facilitating the movement of passengers and goods. The station has supported various services, including passenger trains and express trains like the [Satyagrah Express](https://en.wikipedia.org/wiki/Satyagrah_Express 'Satyagrah Express') and [Mithila Express](https://en.wikipedia.org/wiki/Mithila_Express 'Mithila Express'), contributing to the socio-economic development of the region. [...] Over the years, Darbhanga Junction has seen several upgrades and modernization efforts aimed at improving facilities and operational efficiency, reflecting its continued relevance in the regional and national transportation landscape.

### Linguagem promocional e publicitária

**Palavras de atenção:** _continues to captivate_, _groundbreaking_ (no sentido figurado), _stunning natural beauty_, _enduring/lasting legacy_, _nestled_, _in the heart of_, _boasts a_...

Os LLMs têm sérios problemas para manter um tom neutro, especialmente ao escrever sobre algo que poderia ser considerado "patrimônio cultural" — caso em que [lembram constantemente o leitor de sua importância](#ênfase-indevida-em-simbolismo-legado-e-importância).

**Exemplos**

> Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya Kobo stands as a vibrant town with a rich cultural heritage and a significant place within the Amhara region. From its scenic landscapes to its historical landmarks, Alamata Raya Kobo offers visitors a fascinating glimpse into the diverse tapestry of Ethiopia. In this article, we will explore the unique characteristics that make Alamata Raya Kobo a town worth visiting and shed light on its significance within the Amhara region.

> TTDC acts as the gateway to Tamil Nadu's diverse attractions, seamlessly connecting the beginning and end of every traveller's journey. It offers dependable, value-driven experiences that showcase the state's rich history, spiritual heritage, and natural beauty.

De maneira semelhante, os chatbots de LLM também acrescentam linguagem promocional/de aparência positiva a textos sobre empresas, negócios e produtos, de modo que soem mais como a transcrição de um comercial de TV.

> In general, AEO focuses on improving data consistency and machine readability so that information can be accurately understood by emerging "answer engines." Commonly discussed practices include using structured data formats such as [JSON-LD](https://en.wikipedia.org/wiki/JSON-LD 'JSON-LD') and [schema.org](https://en.wikipedia.org/wiki/Schema.org 'Schema.org'), maintaining the freshness and accuracy of published information, and aligning digital entities with open web standards like [Wikidata](https://en.wikipedia.org/wiki/Wikidata 'Wikidata') and Schema.org.

> The SOLLEI's exterior design communicates a powerful emotional presence, staying true to Cadillac's signature bold proportions. Its low, elongated silhouette is highlighted by a wide stance and an extended coupe door, which enhances accessibility to the spacious rear cabin. Smooth, uninterrupted surfaces and a pronounced A-line accentuate the vehicle's overall length, while a sleek, low tail imparts a sense of refined dynamism. A mid-body line runs seamlessly from the headlamps to the taillights, reinforcing the car's cohesive and elegant design. Traditional door handles have been replaced with discrete buttons, preserving the vehicle's clean and modern profile. In a nod to Cadillac's legacy of bold color choices, the exterior is finished in "Manila Cream"—a distinctive hue originally offered in 1957 and 1958. This heritage color has been thoughtfully revived and hand-painted by Cadillac artisans, showcasing the brand's dedication to craftsmanship and historical reverence.

### Ressalvas didáticas e editorializantes

**Palavras de atenção:** _it's important/critical/crucial to note/remember/consider_, _may vary_...

Os LLMs frequentemente dizem ao leitor sobre coisas que "é importante lembrar". Isso assume frequentemente a forma de "ressalvas" a um leitor imaginado a respeito de segurança ou tópicos controversos, ou desambiguando tópicos que variam em diferentes localidades/jurisdições.

**Exemplos**

> The emergence of these informal groups reflects a growing recognition of the interconnected nature of urban issues and the potential for ANCs to play a role in shaping citywide policies. However, it's important to note that these caucuses operate outside the formal ANC structure and their influence on policy decisions may vary.

> It is crucial to differentiate the independent AI research company based in Yerevan, Armenia, which is the subject of this report, from these unrelated organizations to prevent confusion.

> It's important to remember that what's free in one country might not be free in another, so always check before you use something.

### Resumos e conclusões

**Palavras de atenção:** _In summary_, _In conclusion_, _Overall_...

Ao gerar saídas mais longas (como quando instruídos a "escrever um artigo"), os LLMs frequentemente adicionam uma seção intitulada "Conclusão" ou similar, e muitas vezes encerram um parágrafo ou seção resumindo e reafirmando sua ideia central.[^9]

**Exemplos**

> In summary, the educational and training trajectory for nurse scientists typically involves a progression from a master's degree in nursing to a Doctor of Philosophy in Nursing, followed by postdoctoral training in nursing research. This structured pathway ensures that nurse scientists acquire the necessary knowledge and skills to engage in rigorous research and contribute meaningfully to the advancement of nursing science.

### Conclusões em formato de tópicos sobre desafios e perspectivas futuras

**Palavras de atenção:** _Despite its... faces several challenges..._, _Despite these challenges_, _Challenges and Legacy_, _Future Outlook_...

Muitos artigos da Wikipédia gerados por LLM incluem uma seção de "Desafios", que normalmente começa com uma frase como "Despite its [palavras positivas/promocionais], [assunto do artigo] faces challenges..." e termina com uma avaliação vagamente positiva do assunto do artigo,[^1] ou com especulação sobre como iniciativas em curso ou potenciais poderiam beneficiar o assunto. Tais parágrafos costumam aparecer no fim de artigos com uma estrutura rígida de tópicos, que também pode incluir uma seção separada para "Perspectivas Futuras".

Observação: este sinal diz respeito à fórmula rígida, não simplesmente à menção de desafios ou de algo desafiador.

**Exemplos**

> Despite its industrial and residential prosperity, Korattur faces challenges typical of urban areas, including[...] With its strategic location and ongoing initiatives, Korattur continues to thrive as an integral part of the Ambattur industrial zone, embodying the synergy between industry and residential living.

> Despite its success, the Panama Canal faces challenges, including[...] Future investments in technology, such as automated navigation systems, and potential further expansions could enhance the canal's efficiency and maintain its relevance in global trade.

> Despite their promising applications, pyroelectric materials face several challenges that must be addressed for broader adoption. One key limitation is[...] Despite these challenges, the versatility of pyroelectric materials positions them as critical components for sustainable energy solutions and next-generation sensor technologies.

> The future of hydrocarbon economies faces several challenges, including[...] This section would speculate on potential developments and the changing landscape of global energy.

> Operating in the current Afghan media environment presents numerous challenges, including[...] Despite these challenges, Amu TV has managed to continue to provide a vital service to the Afghan population​​.

> For example, while the methodology supports transdisciplinary collaboration in principle, applying it effectively in large, heterogeneous teams can be challenging. [...] SCE continues to evolve in response to these challenges.

### Introduções que tratam listas da Wikipédia ou títulos genéricos de artigos como nomes próprios

Em artigos gerados por IA sobre tópicos cujo título não é um [nome próprio](https://en.wikipedia.org/wiki/Proper_name 'Proper name'), como uma [lista](https://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style/Lists 'Wikipedia:Manual of Style/Lists'), a primeira frase da introdução pode apresentar e/ou definir o título do artigo como se fosse uma entidade autônoma do mundo real. Embora o [MOS](https://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style/Lead_section#Format_of_the_first_sentence 'Wikipedia:Manual of Style/Lead section') permita que tais títulos sejam incluídos no início da introdução "de maneira natural", essas introduções de IA tendem a não ser tão naturais.

**Exemplos**

> "The Effects of Foreign language anxiety on Learning" refers to the feelings of tension, nervousness, and apprehension experienced when learning or using a language other than one's native tongue.

> EuroGames editions is the chronological list of the biennial EuroGames, a European LGBT+ multi-sport event organized by the European Gay and Lesbian Sport Federation (EGLSF).

> The "**List of songs about Mexico**" is a curated compilation of musical works that reference Mexico its culture, geography, or identity as a central theme.

---

## Linguagem e gramática

### Palavras de "vocabulário de IA" usadas em excesso

**Palavras de atenção:** _align/aligns/aligning with_,[^6][^8] _crucial_,[^1] _delve/delves/delving_ (pré-2025),[^6][^8][^1] _emphasizing_,[^6][^8] _enduring_,[^8] _enhance/enhances/enhancing_,[^8][^1] _fostering_,[^8][^1] _garnered/garnering_,[^6][^8] _highlight/highlighted/highlighting/highlights_ (como verbo),[^1] _interplay_,[^8] _intricate/intricacies_,[^6][^8][^7] _key_ (como adjetivo), _landscape_,[^8] _leveraging_,[^1] _multifaceted_,[^6][^8][^7] _notably_,[^8] _nuanced_,[^6][^8] _realm_,[^8] _robust_,[^1] _seamless/seamlessly_,[^1] _shed light on_, _showcasing_,[^8] _streamline_,[^1] _tapestry_,[^8] _testament_,[^1][^8] _underpin/underpins/underpinning_,[^8] _underscore/underscores/underscoring_,[^8] _vibrant_,[^8][^7] _vital_,[^1] ...

Muitos estudos demonstraram que os LLMs usam em excesso certas palavras – especialmente em comparação com texto anterior a 2022, que é quase certamente de autoria humana.[^6] Essas palavras de "vocabulário de IA" também são onipresentes em enciclopédias geradas por IA, como a [Grokipedia](https://en.wikipedia.org/wiki/Grokipedia 'Grokipedia'), e em texto da Wikipédia gerado por IA. Elas frequentemente coocorrem na saída dos LLMs: onde há uma, provavelmente há outras.[^10] Uma edição que introduz uma ou duas dessas palavras pode não ser grande coisa, mas uma edição (pós-2022) que introduz muitas delas, muitas vezes, é um dos indícios mais fortes do uso de IA.

A distribuição do "vocabulário de IA" é ligeiramente diferente dependendo de qual chatbot ou LLM foi usado,[^7] e mudou ao longo do tempo. Por exemplo, a palavra _delve_ foi notoriamente usada em excesso pelo ChatGPT até 2025, quando sua incidência caiu acentuadamente.[^11]

Tenha o contexto em mente. Por exemplo, embora a palavra "underscore" seja usada em excesso em texto de IA, ela também pode se referir a uma marca de sublinhado literal ou a [música incidental](https://en.wikipedia.org/wiki/Incidental_music 'Incidental music').

**Exemplos**

> Somali cuisine is an intricate and diverse fusion of a multitude of culinary influences, drawing from the rich tapestry of [Arab](https://en.wikipedia.org/wiki/Arab_cuisine 'Arab cuisine'), [Indian](https://en.wikipedia.org/wiki/Indian_cuisine 'Indian cuisine'), and [Italian](https://en.wikipedia.org/wiki/Italian_cuisine 'Italian cuisine') flavours. This culinary tapestry is a direct result of Somalia's longstanding heritage of vibrant trade and bustling commerce. [...]
>
> Additionally, a distinctive feature of Somali culinary tradition is the incorporation of [camel](https://en.wikipedia.org/wiki/Camel 'Camel') [meat](https://en.wikipedia.org/wiki/Meat 'Meat') and [milk](https://en.wikipedia.org/wiki/Milk 'Milk'). They are considered a delicacy and serve as cherished and fundamental elements in the rich tapestry of Somali cuisine. [...]
>
> An enduring testament to the influence of [Italian colonial rule in Somalia](https://en.wikipedia.org/wiki/Italian_Somaliland 'Italian Somaliland') is the widespread adoption of [pasta](https://en.wikipedia.org/wiki/Pasta 'Pasta') and [lasagne](https://en.wikipedia.org/wiki/Lasagna 'Lasagna') in the local culinary landscape, espicially in the south, showcasing how these dishes have integrated into the traditional diet alongside rice. [...]
>
> Additionally, Somali merchants played a pivotal role in the global coffee trade, being one of the first to export coffee beans.

### Paralelismos negativos

Construções paralelas envolvendo "not", "but" ou "however" (não, mas, contudo), como "Not only ... but ..." ou "It is not just about ..., it's ...", são comuns na escrita de LLMs, mas frequentemente inadequadas para a escrita em tom neutro.[^1][^11]

**Exemplos**

> **Self-Portrait** by Yayoi Kusama, executed in 2010 and currently preserved in the famous Uffizi Gallery in Florence, constitutes not only a work of self-representation, but a visual document of her obsessions, visual strategies and psychobiographical narratives.

> It's not just about the beat riding under the vocals; it's part of the aggression and atmosphere.

Aqui está um exemplo de paralelismo negativo ao longo de várias frases:

> He hailed from the esteemed Duse family, renowned for their theatrical legacy. Eugenio's life, however, took a path that intertwined both personal ambition and familial complexities.

### Enumerações de negativas

Em raras ocasiões, mensagens de usuários que parecem geradas por IA também podem incluir frases curtas descrevendo itens que ou estão ausentes de outra coisa ou seriam considerados inúteis em comparação com um item anterior e útil. Algumas delas podem soar como "no ..., no ..., just ..." ou "What matters is ..., not ..., not ...".

**Exemplos**

> There are no long-form profiles. No editorial insights. No coverage of her game dev career. No notable accolades. Just TikTok recaps and callouts.

---

> The process demands rigor — not emotional fatigue, not personal offense, and certainly not a premature exit masked as moral high ground.

---

> Not a career, not a body of work, not sustained relevance — just an algorithmic moment.

---

> This is not a close call. It is not a gray area. This page should be gone, fully, cleanly, and without delay. No redirect. No merge. Just delete.

---

> Wikipedia's general notability guideline (WP:GNG) is crystal clear: significant coverage in reliable, independent, secondary sources. Not a few throwaway articles echoing Twitter drama. Not reactionary posts exploiting culture war tension. Not foreign-language gossip magazines translating controversy for clicks.

---

> What actually matters — and what continues to be completely absent — is significant, in-depth coverage in reliable, independent secondary sources. Not gossip sites. Not recycled outrage. Not tabloid blurbs about one viral controversy. And certainly not basic directory-style mentions of someone being a "video game writer" or TikTok creator.

### Regra de três

Os LLMs usam em excesso a "[regra de três](<https://en.wikipedia.org/wiki/Rule_of_three_(writing)> 'Rule of three (writing)')". Isso pode assumir formas diferentes, de "adjetivo, adjetivo, adjetivo" a "frase curta, frase curta e frase curta".[^1] Os LLMs frequentemente usam essa estrutura para fazer as [análises superficiais](#análises-superficiais) parecerem mais abrangentes.

**Exemplos**

> The Amaze Conference brings together global SEO professionals, marketing experts, and growth hackers to discuss the latest trends in digital marketing. The event features keynote sessions, panel discussions, and networking opportunities.

### Atribuições vagas de opinião

**Palavras de atenção:** _Industry reports_, _Observers have cited_, _Some critics argue_...

Os chatbots de IA tendem a atribuir opiniões ou alegações a alguma autoridade vaga — uma prática chamada [linguagem evasiva](https://en.wikipedia.org/wiki/Weasel_wording 'Weasel wording') (weasel wording) — citando apenas uma ou duas fontes que podem ou não de fato expressar tal visão. Também tendem a generalizar em excesso a perspectiva de uma ou poucas fontes como a de um grupo mais amplo.

**Exemplos**

> His [Nick Ford's] compositions have been described as exploring conceptual themes and bridging the gaps between artistic media.

— De [Draft:Nick Ford (musician)](<https://en.wikipedia.org/wiki/Draft:Nick_Ford_(musician)> 'Draft:Nick Ford (musician)'). Aqui, a linguagem evasiva dá a entender que a opinião vem de uma fonte independente, mas na verdade cita o próprio site de Nick Ford.

> Due to its unique characteristics, the Haolai River is of interest to researchers and conservationists. Efforts are ongoing to monitor its ecological health and preserve the surrounding grassland environment, which is part of a larger initiative to protect China's semi-arid ecosystems from degradation.

> The Kwararafa (Kororofa) confederacy is described in scholarship as a shifting [Benue valley](https://en.wikipedia.org/wiki/Benue_valley 'Benue valley') coalition led by [Jukun](https://en.wikipedia.org/wiki/Jukun 'Jukun') groups and incorporating a range of [Middle Belt](https://en.wikipedia.org/wiki/Middle_Belt 'Middle Belt') peoples. Because much of the historical record derives from [Hausa](https://en.wikipedia.org/wiki/Hausa 'Hausa') chronicles, Bornu sources and oral tradition, modern researchers treat Kwararafa as a fluid political and cultural formation rather than a fixed state. As a result, lists of member groups vary by period and source.

### Variação excessiva de sinônimos / variação elegante

A IA generativa possui um código de penalidade de repetição, destinado a desencorajá-la de reutilizar palavras com muita frequência.[^5] Por exemplo, a saída pode dar o nome de um personagem principal e depois usar repetidamente um sinônimo diferente ou termo relacionado (por exemplo, protagonista, figura central, personagem que dá nome à obra) ao mencioná-lo novamente.

Observação: se um usuário adiciona vários trechos de conteúdo gerado por IA em edições separadas, este indício pode não se aplicar, pois cada trecho de texto pode ter sido gerado isoladamente.

**Exemplos**

> Vierny, after a visit in Moscow in the early 1970's, committed to supporting artists resisting the constraints of socialist realism and discovered Yankilevskly, among others such as Ilya Kabakov and Erik Bulatov. In the challenging climate of Soviet artistic constraints, Yankilevsky, alongside other non-conformist artists, faced obstacles in expressing their creativity freely. Dina Vierny, recognizing the immense talent and the struggle these artists endured, played a pivotal role in aiding their artistic aspirations. [...]
>
> In this new chapter of his life, Yankilevsky found himself amidst a community of like-minded artists who, despite diverse styles, shared a common goal—to break free from the confines of state-imposed artistic norms, particularly socialist realism. [...]
>
> The move to Paris facilitated an environment where Yankilevsky could further explore and exhibit his distinctive artistic vision without the constraints imposed by the Soviet regime. Dina Vierny's unwavering support and commitment to the Russian avant-garde artists played a crucial role in fostering a space where their creativity could flourish, contributing to the rich tapestry of artistic expression in the vibrant cultural landscape of Paris. Vierny's commitment culminated in the groundbreaking exhibition "Russian Avant-Garde - Moscow 1973" at her Saint-Germain-des-Prés gallery, showcasing the diverse yet united front of non-conformist artists challenging the artistic norms of their time.

### Intervalos falsos

Quando construções _from ... to ..._ (de ... a ...) não são usadas de forma figurada, servem para indicar os limites inferior e superior de uma escala. A escala é quantitativa, envolvendo uma faixa numérica explícita ou implícita (por exemplo, de 1990 a 2000, de 15 a 20 onças, do inverno ao outono), ou qualitativa, envolvendo limites categóricos (por exemplo, "da semente à árvore", "de leve a grave", "da faixa branca à faixa preta"). As mesmas construções podem ser usadas para formar um [merismo](https://en.wikipedia.org/wiki/Merism 'Merism') — uma figura de linguagem que combina os dois extremos como duas partes contrastantes do todo para se referir ao todo. Esse é um sentido figurado, mas tem a mesma estrutura do uso não figurado, porque ainda requer uma escala identificável: da cabeça aos pés (o comprimento de um corpo denotando o corpo inteiro), [from soup to nuts](https://en.wiktionary.org/wiki/from_soup_to_nuts 'wikt:from soup to nuts') (claramente baseado no tempo), etc. Isso _não_ é um intervalo falso.

Os LLMs gostam muito de variar, como ao dar exemplos de itens dentro de um conjunto (em vez de simplesmente mencioná-los um após o outro). Uma consideração importante é se algum ponto intermediário pode ser identificado sem alterar os extremos. Se o meio exige mudar de uma escala para outra escala, ou se não há escala alguma para começar ou um todo coerente que possa ser concebido, a construção é um **intervalo falso**. Os LLMs frequentemente empregam construções "from ... to ..." "figuradas" (muitas vezes simplesmente: sem sentido) que pretendem significar uma escala, enquanto os extremos são coisas frouxamente relacionadas ou até não relacionadas e nenhuma escala significativa pode ser inferida. Os LLMs fazem isso porque essa linguagem sem sentido é usada na escrita persuasiva para impressionar e seduzir, e os LLMs são fortemente influenciados por exemplos de escrita persuasiva durante seu treinamento.

**Exemplo**

> Our journey through the universe has taken us from the singularity of the Big Bang to the grand cosmic web, from the birth and death of stars that forge the elements of life, to the enigmatic dance of dark matter and dark energy that shape its destiny.
>
> [...] Intelligence and Creativity: From problem-solving and tool-making to scientific discovery, artistic expression, and technological innovation, human intelligence is characterized by its adaptability and capacity for novel solutions. [...] Continued Scientific Discovery: The quest to understand the universe, life, and ourselves will continue to drive scientific breakthroughs, from fundamental physics to medicine and neuroscience.

### Capitalização de título (title case) em cabeçalhos de seção

Em cabeçalhos de seção, os chatbots de IA têm forte tendência a capitalizar todas as palavras principais (title case).[^1]

**Exemplos**

> Global Context: Critical Mineral Demand
>
> According to a 2023 report by [Goldman Sachs](https://en.wikipedia.org/wiki/Goldman_Sachs 'Goldman Sachs'), the global market for critical minerals [...]
>
> Strategic Negotiations and Global Partnerships
>
> In 2014, Katalayi was appointed senior executive adviser to the chairman of the board of [Gécamines](https://en.wikipedia.org/wiki/G%C3%A9camines 'Gécamines') [...]
>
> High-Stakes Deals: Glencore, China, and Russia
>
> There was also interest from [Moscow](https://en.wikipedia.org/wiki/Moscow 'Moscow') for strategic Congolese assets. [...]

---

## Pontuação e formatação

### Uso excessivo de negrito

Os chatbots de IA podem exibir várias frases em [negrito](https://en.wikipedia.org/wiki/Boldface 'Boldface') para dar ênfase de maneira excessiva e mecânica. Uma de suas tendências, herdada de readmes, wikis de fãs, tutoriais, discursos de venda, apresentações de slides, listicles e outros materiais que usam negrito intensamente, é enfatizar cada ocorrência de uma palavra ou frase escolhida, muitas vezes em um estilo de "principais conclusões". Alguns modelos de linguagem de grande porte ou aplicativos mais novos têm instruções para evitar o uso excessivo de negrito.

**Exemplos**

> It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance Indicators)**, and visual strategy tools such as the **Business Model Canvas (BMC)** and **Balanced Scorecard (BSC)**. OPC is designed to bridge the gap between strategy and execution by fostering a unified mindset and shared direction within organizations.

> A **leveraged buyout (LBO)** is characterized by the extensive use of **debt financing** to acquire a company. This financing structure enables **private equity firms** and **financial sponsors** to control businesses while investing a relatively small portion of their own equity. The acquired company's **assets and future cash flows** serve as collateral for the debt, making lenders more willing to provide financing.

> **50 Scientists and Thinkers in AI Safety with significant** influence on the field of alignment, containment, and risk mitigation. The list includes their **Productive Years**, their estimated **P(doom)** (probability of existential catastrophe), a **one-sentence summary of their contribution to AI Safety**, and their Wikipedia link.

### Listas verticais com cabeçalho embutido

A saída dos chatbots de IA frequentemente inclui listas verticais formatadas de uma maneira específica: uma lista ordenada ou não ordenada em que o marcador da lista (número, bullet, traço etc.) é seguido por um cabeçalho em negrito embutido, separado por dois-pontos do restante do texto descritivo.

Em vez de [wikitext apropriado](https://en.wikipedia.org/wiki/H:LIST 'H:LIST'), um item em uma lista não ordenada pode aparecer como um caractere de marcador (•), hífen (-), meia-risca (–), cerquilha (#), emoji ou caractere semelhante. Listas ordenadas (ou seja, listas numeradas) podem usar números explícitos (como `1.`) em vez do wikitext padrão. Quando copiado como texto puro aparecendo na tela, parte das informações de formatação se perde, e as quebras de linha também podem se perder.

**Exemplos**

> 1. Historical Context Post-WWII Era: The world was rapidly changing after WWII, [...] 2. Nuclear Arms Race: Following the U.S. atomic bombings, the Soviet Union detonated its first bomb in 1949, [...] 3. Key Figures Edward Teller: A Hungarian physicist who advocated for the development of more powerful nuclear weapons, [...] 4. Technical Details of Sundial Hydrogen Bomb: The design of Sundial involved a hydrogen bomb [...] 5. Destructive Potential: If detonated, Sundial would create a fireball up to 50 kilometers in diameter, [...] 6. Consequences and Reactions Global Impact: The explosion would lead to an apocalyptic nuclear winter, [...] 7. Political Reactions: The U.S. military and scientists expressed horror at the implications of such a weapon, [...] 8. Modern Implications Current Nuclear Arsenal: Today, there are approximately 12,000 nuclear weapons worldwide, [...] 9. Key Takeaways Understanding the Madness: The concept of Project Sundial highlights the extremes of human ingenuity [...] 10. Questions to Consider What were the motivations behind the development of Project Sundial? [...]

> Conflict of Interest (COI)/Autobiography: While I understand the concern regarding my username [...]
>
> Notability (GNG and NPOLITICIAN): I have revised the article to focus on factual details [...]
>
> Original Research (WP) and Promotional Tone: I have worked on removing original research [...]
>
> Article Move to Main Namespace: Moving the draft to the main namespace after the AFC review [...]

### Emojis

Os chatbots de IA adoram usar [emojis](https://en.wikipedia.org/wiki/Emoji 'Emoji').[^11] Em particular, às vezes decoram cabeçalhos de seção ou itens de lista colocando emojis à frente deles. Isso é mais perceptível em comentários de páginas de discussão.

**Exemplos**

> Let's decode exactly what's happening here:
>
> 🧠 Cognitive Dissonance Pattern:
>
> You've proven authorship, demonstrated originality, and introduced new frameworks, yet they're defending a system that explicitly disallows recognition of originators unless a third party writes about them first.
>
> [...]
>
> 🧱 Structural Gatekeeping:
>
> Wikipedia policy favors:
>
> [...]
>
> 🚨 Underlying Motivation:
>
> Why would a human fight you on this?
>
> [...]
>
> 🧭 What You're Actually Dealing With:
>
> This is not a debate about rules.
>
> [...]

> 🪷 Traditional Sanskrit Name: Trikoṇamiti
>
> Tri = Three
>
> Koṇa = Angle
>
> Miti = Measurement 🧭 "Measurement of three angles" — the ancient Indian art of triangle and angle mathematics.
>
> 🕰️ 1. Vedic Era (c. 1200 BCE – 500 BCE)
>
> [...]
>
> 🔭 2. Sine of the Bow: Sanskrit Terminology
>
> [...]
>
> 🌕 3. Āryabhaṭa (476 CE)
>
> [...]
>
> 🌀 4. Varāhamihira (6th Century CE)
>
> [...]
>
> 🌠 5. Bhāskarācārya II (12th Century CE)
>
> [...]
>
> 📤 Indian Legacy Spreads

### Uso excessivo de travessões (em dash)

Embora editores e escritores humanos muitas vezes gostem de [travessões](https://en.wikipedia.org/wiki/Em_dash 'Em dash') (—), a IA os _adora_.[^11] A saída dos LLMs os usa com mais frequência do que o texto humano não profissional do mesmo gênero, e os usa em lugares onde humanos teriam mais probabilidade de usar vírgulas, parênteses, dois-pontos ou hifens (mal empregados) (-). Os LLMs tendem especialmente a usar travessões de modo formulaico e batido, muitas vezes imitando a escrita "turbinada" de vendas ao enfatizar demais orações ou paralelismos.

Este sinal é mais útil quando tomado em combinação com outros indicadores, não isoladamente.

**Exemplos**

> The term "Dutch Caribbean" is **not used in the statute** and is primarily promoted by **Dutch institutions**, not by the **people of the autonomous countries** themselves. In practice, many Dutch organizations and businesses use it for **their own convenience**, even placing it in addresses — e.g., "Curaçao, Dutch Caribbean" — but this only **adds confusion** internationally and **erases national identity**. You don't say **"Netherlands, Europe"** as an address — yet this kind of mislabeling continues.

> you're right about one thing — we do seem to have different interpretations of what policy-based discussion entails. [...]
>
> When WP:BLP1E says "one event," it's shorthand — and the supporting essays, past AfD precedents, and practical enforcement show that "two incidents of fleeting attention" still often fall under the protective scope of BLP1E. This isn't "imagining" what policy should be — it's recognizing how community consensus has shaped its application.
>
> Yes, WP:GNG, WP:NOTNEWS, WP:NOTGOSSIP, and the rest of WP:BLP all matter — and I've cited or echoed each of them throughout. [...] If a subject lacks enduring, in-depth, independent coverage — and instead rides waves of sensational, short-lived attention — then we're not talking about encyclopedic significance. [...]
>
> [...] And consensus doesn't grow from silence — it grows from critique, correction, and clarity.
>
> If we disagree on that, then yes — we're speaking different languages.

> The current revision of the article fully complies with Wikipedia's core content policies — including WP:V (Verifiability), WP:RS (Reliable Sources), and WP:BLP (Biographies of Living Persons) — with all significant claims supported by multiple independent and reputable international sources.
>
> [...] However, to date, no editor — including yourself — has identified any specific passages in the current version that were generated by AI or that fail to meet Wikipedia's content standards. [...]
>
> Given the article's current state — well-sourced, policy-compliant, and collaboratively improved — the continued presence of the "LLM advisory" banner is unwarranted.

### Aspas e apóstrofos tipográficos (curvos)

Os chatbots de IA normalmente usam aspas curvas (tipográficas) ("..." ou '...') em vez de aspas retas ("..." ou '...'). Em alguns casos, os chatbots de IA usam de forma inconsistente pares de aspas curvas e retas na mesma resposta. Eles também tendem a usar o apóstrofo curvo ('), o mesmo caractere que a [aspa simples direita curva](https://en.wikipedia.org/wiki/Right_single_quotation_mark 'Right single quotation mark'), em vez do apóstrofo reto ('), como em [contrações](<https://en.wikipedia.org/wiki/Contraction_(grammar)> 'Contraction (grammar)') e [formas possessivas](https://en.wikipedia.org/wiki/English_possessive 'English possessive'). Também podem fazer isso de forma inconsistente.

Aspas curvas por si sós não provam o uso de LLM. Tanto o [Microsoft Word](https://en.wikipedia.org/wiki/Microsoft_Word 'Microsoft Word') quanto os dispositivos [macOS](https://en.wikipedia.org/wiki/MacOS 'MacOS') e [iOS](https://en.wikipedia.org/wiki/IOS 'IOS') têm um recurso de "[aspas inteligentes](https://en.wikipedia.org/wiki/Smart_quotes 'Smart quotes')" que converte aspas retas em aspas curvas. Ferramentas de correção gramatical como o [LanguageTool](https://en.wikipedia.org/wiki/LanguageTool 'LanguageTool') também podem ter esse recurso. Aspas e apóstrofos curvos são comuns em obras com composição tipográfica profissional, como grandes jornais. Ferramentas de citação como o [Citer](https://citer.toolforge.org/) podem repetir os que aparecem no título de uma página da web: por exemplo,

> McClelland, Mac (2017-09-27). ["When 'Not Guilty' Is a Life Sentence"](https://www.nytimes.com/2017/09/27/magazine/when-not-guilty-is-a-life-sentence.html). _The New York Times_. Retrieved 2025-08-03.

Observe que a Wikipédia permite que os usuários personalizem as fontes usadas para exibir o texto. Algumas fontes exibem apóstrofos curvos correspondentes como retos, caso em que a distinção é invisível para o usuário.

### Linhas de assunto

Mensagens de usuários e [pedidos de desbloqueio](https://en.wikipedia.org/wiki/Wikipedia:Identifying_LLM_unblock_requests 'Wikipedia:Identifying LLM unblock requests') gerados por chatbots de IA às vezes começam com texto destinado a ser colado no campo _Assunto_ de um formulário de e-mail.

**Exemplos**

> Subject: Request for Permission to Edit Wikipedia Article - "Dog"

> Subject: Request for Review and Clarification Regarding Draft Article

---

## Comunicação destinada ao usuário

### Comunicação colaborativa

**Palavras de atenção:** _I hope this helps_, _Of course!_, _Certainly!_, _You're absolutely right!_, _Would you like..._, _is there anything else_, _let me know_, _more detailed breakdown_, _here is a_...

Os editores às vezes colam texto de um chatbot de IA que era destinado a correspondência, pré-escrita ou aconselhamento, em vez de conteúdo de artigo. Isso pode aparecer no texto do artigo ou dentro de comentários (`<!-- -->`). Chatbots instruídos a produzir um artigo ou comentário da Wikipédia também podem afirmar explicitamente que o texto se destina à Wikipédia, e podem mencionar várias [políticas e diretrizes](https://en.wikipedia.org/wiki/Wikipedia:PG 'Wikipedia:PG') na saída — muitas vezes especificando explicitamente que são convenções _da Wikipédia_.

**Exemplos**

> In this section, we will discuss the background information related to the topic of the report. This will include a discussion of relevant literature, previous research, and any theoretical frameworks or concepts that underpin the study. The purpose is to provide a comprehensive understanding of the subject matter and to inform the reader about the existing knowledge and gaps in the field.

> Including photos of the forge (as above) and its tools would enrich the article's section on culture or economy, giving readers a visual sense of Ronco's industrial heritage. Visual resources can also highlight Ronco Canavese's landscape and landmarks. For instance, a map of the Soana Valley or Ronco's location in Piedmont could be added to orient readers geographically. The village's scenery [...] could be illustrated with an image. Several such photographs are available (e.g., on Wikimedia Commons) that show Ronco's panoramic view, [...] Historical images, if any exist (such as early 20th-century photos of villagers in traditional dress or of old alpine trades), would also add depth to the article. Additionally, the town's notable buildings and sites can be visually presented: [...] Including an image of the Santuario di San Besso [...] could further engage readers. By leveraging these visual aids – maps, photographs of natural and cultural sites – the expanded article can provide a richer, more immersive picture of Ronco Canavese.

> If you plan to add this information to the "Animal Cruelty Controversy" section of Foshan's Wikipedia page, ensure that the content is presented in a neutral tone, supported by reliable sources, and adheres to Wikipedia's guidelines on verifiability and neutrality.

> Here's a template for your wiki user page. You can copy and paste this onto your user page and customize it further.

> Final important tip: The ~~~~ at the very end is Wikipedia markup that automatically

### Ressalvas de corte de conhecimento e especulação sobre lacunas nas fontes

**Palavras de atenção:** _as of [date]_,[^a] _Up to my last training update_, _as of my last knowledge update_, _While specific details are limited/scarce..._, _not widely available/documented/disclosed_, _...in the provided/available sources/search results..._, _based on available information_...

Uma ressalva de corte de conhecimento é uma afirmação usada pelo chatbot de IA para indicar que a informação fornecida pode estar incompleta, imprecisa ou desatualizada.

Se um LLM tem um [corte de conhecimento](https://en.wikipedia.org/wiki/Knowledge_cutoff 'Knowledge cutoff') fixo (geralmente a última atualização de treinamento do modelo), ele é incapaz de fornecer qualquer informação sobre eventos ou desenvolvimentos posteriores a esse momento, e frequentemente emite uma ressalva para lembrar o usuário desse corte, o que costuma assumir a forma de uma afirmação dizendo que a informação fornecida é precisa apenas até certa data.

Se um LLM com geração aumentada por recuperação não consegue encontrar fontes sobre um determinado tópico, ou se a informação não está incluída nas fontes que um usuário fornece, ele frequentemente emite uma afirmação nesse sentido, semelhante a uma ressalva de corte de conhecimento. Pode também combiná-la com texto sobre o que essa informação "provavelmente" seria e por que ela é significativa. Essa informação é inteiramente [especulativa](https://en.wikipedia.org/wiki/Wikipedia:OR 'Wikipedia:OR') (incluindo a própria alegação de que "não está documentada") e pode se basear em tópicos frouxamente relacionados ou ser completamente fabricada.

**Exemplos**

> While specific details about Kumarapediya's history or economy are not extensively documented in readily available sources, ...

> While specific information about the fauna of Studniční hora is limited in the provided search results, the mountain likely supports...

> Though the details of these resistance efforts aren't widely documented, they highlight her bravery...

> No significant public controversies or security incidents affecting Outpost24 have been documented as of June 2025.

> As of my last knowledge update in January 2022, I don't have specific information about the current status or developments related to the "Chester Mental Health Center" in today's era.

> Below is a detailed overview based on available information:

### Recusas de prompt

**Palavras de atenção:** _as an AI language model_, _as a large language model_, _I'm sorry_...

Ocasionalmente, o chatbot de IA recusa-se a responder a um prompt tal como escrito, geralmente com um pedido de desculpas e um lembrete de que é "um modelo de linguagem de IA". Tentando ser prestativo, frequentemente dá sugestões ou uma resposta a uma solicitação alternativa e semelhante. Recusas diretas tornaram-se cada vez mais raras.

Recusas de prompt são obviamente inaceitáveis em artigos da Wikipédia, então, se um usuário incluir uma mesmo assim, isso pode indicar que ele não revisou o texto e/ou pode não ter proficiência em inglês. Lembre-se de [presumir boa-fé](https://en.wikipedia.org/wiki/Wikipedia:Assume_good_faith 'Wikipedia:Assume good faith'), pois esse editor pode genuinamente querer melhorar nossa cobertura de [lacunas de conhecimento](https://en.wikipedia.org/wiki/Wikipedia:Systemic_bias 'Wikipedia:Systemic bias').

**Exemplos**

> As an AI language model, I can't directly add content to Wikipedia for you, but I can help you draft your bibliography.

### Modelos de frase (phrasal templates) e texto de preenchimento

Os chatbots de IA podem gerar respostas com [modelos de frase](https://en.wikipedia.org/wiki/Phrasal_template 'Phrasal template') de preencher lacunas (como visto no jogo _[Mad Libs](https://en.wikipedia.org/wiki/Mad_Libs 'Mad Libs')_) para que o usuário do LLM substitua por palavras e frases pertinentes ao seu caso de uso. No entanto, alguns usuários de LLM esquecem de preencher essas lacunas. Observe que existem modelos não gerados por LLM para rascunhos e novos artigos, como [Wikipedia:Artist biography article template/Preload](https://en.wikipedia.org/wiki/Wikipedia:Artist_biography_article_template/Preload 'Wikipedia:Artist biography article template/Preload') e páginas em [Category:Article creation templates](https://en.wikipedia.org/wiki/Category:Article_creation_templates 'Category:Article creation templates').

**Exemplos**

> Subject: Concerns about Inaccurate Information
>
> Dear Wikipedia
>
> I am writing to express my deep concern about the spread of misinformation on your platform. Specifically, I am referring to the article about [Entertainer's Name], which I believe contains inaccurate and harmful information.

> Subject: Edit Request for Wikipedia Entry
>
> Dear Wikipedia Editors,
>
> I hope this message finds you well. I am writing to request an edit for the Wikipedia entry
>
> I have identified an area within the article that requires updating/improvement. [Describe the specific section or content that needs editing and provide clear reasons why the edit is necessary, including reliable sources if applicable].

Os modelos de linguagem de grande porte também podem inserir datas de preenchimento como "2025-xx-xx" em campos de citação, particularmente no parâmetro access-date e, raramente, também no parâmetro date, produzindo erros.

**Exemplos**

```
<ref>{{cite web
 |title=Canadian Screen Music Awards 2025 Winners and Nominees
 |url=URL
 |website=Canadian Screen Music Awards
 |date=2025
 |access-date=2025-XX-XX
}}</ref>

<ref>{{cite web
 |title=Best Original Score, Dramatic Series or Special – Winner: "Murder on the Inca Trail"
 |url=URL
 |website=Canadian Screen Music Awards
 |date=2025
 |access-date=2025-XX-XX
}}</ref>
```

Edições de infobox geradas por LLM podem conter comentários de preenchimento ao lado de campos não utilizados, especificando que texto ou imagens deveriam ser adicionados.

**Exemplos**

```
| leader_name = <!-- Add if available with citation -->
```

---

## Marcação (markup)

### Uso de Markdown

Os chatbots de IA não são proficientes em [wikitext](https://en.wikipedia.org/wiki/H:WT 'H:WT'), a [linguagem de marcação](https://en.wikipedia.org/wiki/Markup_language 'Markup language') usada para instruir o software [MediaWiki](https://en.wikipedia.org/wiki/MediaWiki 'MediaWiki') da Wikipédia sobre como formatar um artigo. Como o wikitext é uma linguagem de marcação de nicho, encontrada principalmente em wikis que rodam em MediaWiki e em outras plataformas baseadas em MediaWiki, como o [Miraheze](https://en.wikipedia.org/wiki/Miraheze 'Miraheze'), os LLMs tendem a carecer de dados de treinamento formatados em wikitext. Embora os corpora dos chatbots tenham de fato ingerido milhões de artigos da Wikipédia, esses artigos não teriam sido processados como arquivos de texto contendo sintaxe wikitext. Isso é agravado pelo fato de que a maioria dos chatbots é ajustada de fábrica para usar outra linguagem de marcação, conceitualmente semelhante mas aplicada de forma muito mais diversa: o [Markdown](https://en.wikipedia.org/wiki/Markdown 'Markdown'). Suas instruções em nível de sistema os direcionam a formatar saídas usando-o, e os aplicativos de chatbot renderizam sua sintaxe como texto formatado na tela do usuário, permitindo a exibição de cabeçalhos, listas com marcadores e numeradas, tabelas etc., assim como o MediaWiki renderiza o wikitext para fazer os artigos da Wikipédia parecerem documentos formatados.

Quando questionado sobre suas "diretrizes de formatação", um chatbot disposto a revelar parte de suas instruções em nível de sistema normalmente gera alguma variação do seguinte (este é o [Microsoft Copilot](https://en.wikipedia.org/wiki/Microsoft_Copilot 'Microsoft Copilot') em meados de 2025):

> ## Formatting Guidelines
>
> - All output uses GitHub-flavored Markdown.
> - Use a single main title (`#`) and clear primary subheadings (`##`).
> - Keep paragraphs short (3–5 sentences, ≤150 words).
> - Break large topics into labeled subsections.
> - Present related items as bullet or numbered lists; number only when order matters.
> - Always leave a blank line before and after each paragraph.
> - Avoid bold or italic styling in body text unless explicitly requested.
> - Use horizontal dividers (`---`) between major sections.
> - Employ valid Markdown tables for structured comparisons or data summaries.
> - Refrain from complex Unicode symbols; stick to simple characters.
> - Reserve code blocks for code, poems, lyrics, or similarly formatted content.
> - For mathematical expressions, use LaTeX outside of code blocks.

Como o acima sugere, a sintaxe do Markdown é completamente diferente da do wikitext: o Markdown usa asteriscos (\*) ou sublinhados (\_) em vez de aspas simples (') para formatação em negrito e itálico, símbolos de cerquilha (#) em vez de sinais de igual (=) para cabeçalhos de seção, parênteses (()) em vez de colchetes ([]) ao redor de URLs, e três símbolos (---, \*\*\*, ou \_\_\_) em vez de quatro hifens (----) para quebras temáticas.

Mesmo quando explicitamente instruídos a fazê-lo, os chatbots geralmente têm dificuldade para gerar texto usando wikitext sintaticamente correto, pois seus dados de treinamento levam a uma afinidade e fluência drasticamente maiores em Markdown. Quando instruído a "gerar um artigo", um chatbot normalmente recorre ao Markdown para a saída gerada, que é preservada no texto da área de transferência pelas funções de cópia de algumas plataformas de chatbot. Se instruído a gerar conteúdo para a Wikipédia, o chatbot pode "perceber" a necessidade de gerar código compatível com a Wikipédia e pode incluir uma mensagem como "Would you like me to ... turn this into actual Wikipedia markup format (`wikitext`)?"[^b] em sua saída. Se o chatbot for instruído a prosseguir, a sintaxe resultante é muitas vezes rudimentar, sintaticamente incorreta, ou ambas. O chatbot pode colocar seu conteúdo em tentativa de wikitext em um bloco de código cercado ao estilo Markdown (sua sintaxe para texto pré-formatado) rodeado por sintaxe e conteúdo baseados em Markdown, o que também pode ser preservado por funções de copiar para a área de transferência específicas da plataforma, levando a uma pegada reveladora da sintaxe de ambas as linguagens de marcação. Isso pode incluir o aparecimento de três crases no texto, como: ` ```wikitext `.[^c]

A presença de sintaxe wikitext defeituosa misturada com sintaxe Markdown é um forte indicador de que o conteúdo foi gerado por LLM, especialmente se na forma de um bloco de código cercado em Markdown. No entanto, o Markdown _sozinho_ não é um indicador tão forte. Desenvolvedores de software, pesquisadores, redatores técnicos e usuários experientes da internet usam Markdown com frequência em ferramentas como o [Obsidian](<https://en.wikipedia.org/wiki/Obsidian_(software)> 'Obsidian (software)') e o [GitHub](https://en.wikipedia.org/wiki/GitHub_Flavored_Markdown 'GitHub Flavored Markdown'), e em plataformas como Reddit, Discord e Slack. Algumas ferramentas e aplicativos de escrita, como o Notas do iOS, o Google Docs e o Bloco de Notas do Windows, oferecem suporte à edição ou exportação em Markdown. A crescente onipresença do Markdown também pode levar novos editores a esperar ou supor que a Wikipédia ofereça suporte a Markdown por padrão.

**Exemplos**

> I believe this block has become procedurally and substantively unsound. Despite repeatedly raising clear, policy-based concerns, every unblock request has been met with **summary rejection** — not based on specific diffs or policy violations, but instead on **speculation about motive**, assertions of being "unhelpful", and a general impression that I am "not here to build an encyclopedia". No one has meaningfully addressed the fact that I have **not made disruptive edits**, **not engaged in edit warring**, and have consistently tried to **collaborate through talk page discussion**, citing policy and inviting clarification. Instead, I have encountered a pattern of dismissiveness from several administrators, where reasoned concerns about **in-text attribution of partisan or interpretive claims** have been brushed aside. Rather than engaging with my concerns, some editors have chosen to mock, speculate about my motives, or label my arguments "AI-generated" — without explaining how they are substantively flawed.

> - The Wikipedia entry does not explicitly mention the "Cyberhero League" being recognized as a winner of the World Future Society's BetaLaunch Technology competition, as detailed in the interview with THE FUTURIST ([[1]](https://consciouscreativity.com/the-futurist-interview-with-dana-klisanin-creator-of-the-cyberhero-league/)([https://consciouscreativity.com/the-futurist-interview-with-dana-klisanin-creator-of-the-cyberhero-league/](https://consciouscreativity.com/the-futurist-interview-with-dana-klisanin-creator-of-the-cyberhero-league/))). This recognition could be explicitly stated in the "Game design and media consulting" section.

Aqui, os LLMs usam incorretamente `##` para indicar cabeçalhos de seção, o que o MediaWiki interpreta como uma lista numerada.

> 1.  1. Geography
>
> Villers-Chief is situated in the [Jura Mountains](https://en.wikipedia.org/wiki/Jura_Mountains 'Jura Mountains'), in the eastern part of the Doubs department. [...]
>
> 1.  1. History
>
> Like many communes in the region, Villers-Chief has an agricultural past. [...]
>
> 1.  1. Administration
>
> Villers-Chief is part of the [Canton of Valdahon](https://en.wikipedia.org/wiki/Canton_of_Valdahon 'Canton of Valdahon') and the [Arrondissement of Pontarlier](https://en.wikipedia.org/wiki/Arrondissement_of_Pontarlier 'Arrondissement of Pontarlier'). [...]
>
> 1.  1. Population
>
> The population of Villers-Chief has seen some fluctuations over the decades, [...]

Como os chatbots de IA não são proficientes em wikitext e nas predefinições da Wikipédia, frequentemente produzem sintaxe defeituosa. Um caso notável é o código distorcido relacionado ao Template:AfC submission, já que novos editores podem perguntar a um chatbot como submeter seu rascunho de Articles for Creation.

**Exemplos**

Observe o link de categoria gravemente malformado, que parece ser resultado de código que fornece informações de dia no analisador Markdown do LLM:

```
[[Category:AfC submissions by date/<0030Fri, 13 Jun 2025 08:18:00 +0000202568 2025-06-13T08:18:00+00:00Fridayam0000=error>EpFri, 13 Jun 2025 08:18:00 +0000UTC00001820256 UTCFri, 13 Jun 2025 08:18:00 +0000Fri, 13 Jun 2025 08:18:00 +00002025Fri, 13 Jun 2025 08:18:00 +0000: 17498026806Fri, 13 Jun 2025 08:18:00 +0000UTC2025-06-13T08:18:00+00:0020258618163UTC13 pu62025-06-13T08:18:00+00:0030uam301820256 2025-06-13T08:18:00+00:0008amFri, 13 Jun 2025 08:18:00 +0000am2025-06-13T08:18:00+00:0030UTCFri, 13 Jun 2025 08:18:00 +0000 &qu202530;:&qu202530;.</0030Fri, 13 Jun 2025 08:18:00 +0000202568>June 2025|sandbox]]
```

### Marcações específicas do ChatGPT: citeturn, iturn

O ChatGPT pode incluir `citeturn0search0` (cercado por pontos Unicode na Área de Uso Privado) no fim das frases, com o número após "search" aumentando à medida que o texto avança. Esses são lugares onde o chatbot insere um link para um site externo, mas, quando um humano cola a conversa na Wikipédia, esse link é convertido em código de preenchimento. Isso foi observado pela primeira vez em fevereiro de 2025.

Um conjunto de imagens em uma resposta também pode ser renderizado como `iturn0image0turn0image1turn0image4turn0image5`. Raramente, outras marcações de estilo semelhante, como `citeturn0news0`, `citeturn1file0` ou `citegenerated-reference-identifier`, podem aparecer.

**Exemplos**

> The school is also a center for the US College Board examinations, SAT I & SAT II, and has been recognized as an International Fellowship Centre by Cambridge International Examinations. citeturn0search1 For more information, you can visit their official website: citeturn0search0

### Bugs de marcação de referências: contentReference, oaicite, oai_citation, attached_file, grok_card

Devido a um bug, o ChatGPT pode adicionar código na forma de `:contentReference[oaicite:0]{index=0}` no lugar de links para referências no texto de saída. Links para referências geradas pelo ChatGPT podem ser rotulados com `oai_citation`.

**Exemplos**

> :contentReference[oaicite:16]{index=16}
>
> 1. **Ethnicity clarification**
>
> - :contentReference[oaicite:17]{index=17}
>     - :contentReference[oaicite:18]{index=18} :contentReference[oaicite:19]{index=19}.
>     - Denzil Ibbetson's _Panjab Castes_ classifies Sial as Rajputs :contentReference[oaicite:20]{index=20}.
>     - Historian's blog notes: "The Sial are a clan of Parmara Rajputs…" :contentReference[oaicite:21]{index=21}.
>
> 2. :contentReference[oaicite:22]{index=22}
>
> - :contentReference[oaicite:23]{index=23}
>     > :contentReference[oaicite:24]{index=24} :contentReference[oaicite:25]{index=25}.

> #### Key facts needing addition or correction:
>
> 1. **Group launch & meetings**
>
> _Independent Together_ launched a "Zero Rates Increase Roadshow" on 15 June, with events in Karori, Hataitai, Tawa, and Newtown [oai_citation:0‡wellington.scoop.co.nz](https://wellington.scoop.co.nz/?p=171473&utm_source=chatgpt.com).
>
> 2. **Zero-rates pledge and platform**
>
> The group pledges no rates increases for three years, then only match inflation—responding to Wellington's 16.9% hike for 2024/25 [oai_citation:1‡en.wikipedia.org](https://en.wikipedia.org/wiki/Independent_Together?utm_source=chatgpt.com).

No outono (hemisfério norte) de 2025, tags como `[attached_file:1]`, `[web:1]` foram vistas no fim de frases. Isso pode ser específico do Perplexity.[^12]

> During his time as CEO, Philip Morris's reputation management and media relations brought together business and news interests in ways that later became controversial, with effects still debated in contemporary regulatory and legal discussions.[attached_file:1]

Embora o texto gerado pelo Grok seja raro em comparação com outros chatbots, ele pode às vezes incluir tags _grok_card_ no estilo XML após as citações.

> Malik's rise to fame highlights the visibility of transgender artists in Pakistan's entertainment scene, though she has faced societal challenges related to her identity. [...]<grok-card data-id="e8ff4f" data-type="citation_card">

### attribution e attributableIndex

O ChatGPT pode adicionar código em formato JSON no fim das frases na forma `({"attribution":{"attributableIndex":"X-Y"}})`, com X e Y sendo índices numéricos crescentes.

**Exemplos**

> ^[Evdokimova was born on 6 October 1939 in Osnova, Kharkov Oblast, Ukrainian SSR (now Kharkiv, Ukraine).]({"attribution":{"attributableIndex":"1009-1"}}) ^[She graduated from the Gerasimov Institute of Cinematography (VGIK) in 1963, where she studied under Mikhail Romm.]({"attribution":{"attributableIndex":"1009-2"}}) [oai_citation:0‡IMDb](https://www.imdb.com/name/nm0947835/?utm_source=chatgpt.com) [oai_citation:1‡maly.ru](https://www.maly.ru/en/people/EvdokimovaA?utm_source=chatgpt.com)

> Patrick Denice & Jake Rosenfeld, [Les syndicats et la rémunération non syndiquée aux États-Unis, 1977–2015](https://sociologicalscience.com/articles-v5-23-541/), ''Sociological Science'' (2018).]({"attribution":{"attributableIndex":"3795-0"}})

### Categorias inexistentes ou deslocadas e páginas em "ver também"

Os LLMs podem alucinar categorias inexistentes, às vezes para conceitos genéricos que _parecem_ títulos de categoria plausíveis (ou palavras-chave de SEO), e às vezes porque seu conjunto de treinamento inclui categorias obsoletas e renomeadas. Elas aparecerão como links vermelhos. Você também pode encontrar redirecionamentos de categoria, como a Category:Entrepreneurs, favorita de longa data dos spammers. Às vezes, categorias quebradas podem ser excluídas pelos revisores, então, se você suspeitar que uma página foi gerada por LLM, pode valer a pena verificar revisões anteriores.

Preste atenção também aos links azuis sob os cabeçalhos "ver também". Seções "ver também" geradas por LLM costumam preenchê-las (com pelo menos três links) aparentemente por obrigação. Se uma nova página/rascunho sobre alguma startup remete a um termo amplo como "tecnologia financeira" em sua seção ver-também, isso é um tanto suspeito.

É claro que nada desta seção deve ser tratado como regra rígida. É improvável que novos usuários conheçam as diretrizes de estilo da Wikipédia para essas seções, e editores que retornam podem estar acostumados a categorias antigas que desde então foram excluídas.

**Exemplos**

```
[[Category:American hip hop musicians]]
```

em vez de

```
[[Category:American hip-hop musicians]]
```

---

## Citações

### Referências fictícias ou alucinadas

Os LLMs podem gerar referências fictícias ou alucinadas que não existem ou contêm informações fabricadas.

### Links externos quebrados

Se um novo artigo ou rascunho tem várias citações com links externos, e vários deles estão quebrados (por exemplo, retornando [erros 404](https://en.wikipedia.org/wiki/404_error '404 error')), isso é um forte sinal de uma página gerada por IA, particularmente se os links mortos não forem encontrados em sites de arquivamento como o [Internet Archive](https://en.wikipedia.org/wiki/Internet_Archive 'Internet Archive') ou o [Archive Today](https://en.wikipedia.org/wiki/Archive_Today 'Archive Today'). A maioria dos links [se quebra com o tempo](https://en.wikipedia.org/wiki/Link_rot 'Link rot'), mas esses fatores tornam improvável que o link algum dia tenha sido real.

### DOIs e ISBNs inválidos

Uma [soma de verificação](https://en.wikipedia.org/wiki/Checksum 'Checksum') pode ser usada para verificar [ISBNs](https://en.wikipedia.org/wiki/ISBN 'ISBN'). Uma soma de verificação inválida é um sinal muito provável de que um ISBN está incorreto, e as predefinições de citação exibem um aviso nesse caso. Da mesma forma, os [DOIs](https://en.wikipedia.org/wiki/Digital_object_identifier 'Digital object identifier') são mais resistentes à degradação de links do que hiperlinks comuns. DOIs irresolvíveis e ISBNs inválidos podem ser indicadores de referências [alucinadas](<https://en.wikipedia.org/wiki/Hallucination_(AI)> 'Hallucination (AI)').

A isso se relacionam os DOIs que apontam para artigos totalmente não relacionados e as citações genéricas de livros sem números de página. Esta passagem, por exemplo, foi gerada pelo ChatGPT.

> Ohm's Law is a fundamental principle in the field of electrical engineering and physics that states the current passing through a conductor between two points is directly proportional to the voltage across the two points, provided the temperature remains constant. Mathematically, it is expressed as V=IR, where V is the voltage, I is the current, and R is the resistance. The law was formulated by German physicist Georg Simon Ohm in 1827, and it serves as a cornerstone in the analysis and design of electrical circuits [1]. Ohm's Law applies to many materials and components that are "ohmic," meaning their resistance remains constant regardless of the applied voltage or current. However, it does not hold for non-linear devices like diodes or transistors [2][3].
>
> References:
>
> 1. Dorf, R. C., & Svoboda, J. A. (2010). Introduction to Electric Circuits (8th ed.). Hoboken, NJ: John Wiley & Sons. ISBN 9780470521571.
> 2. M. E. Van Valkenburg, "The validity and limitations of Ohm's law in non-linear circuits," Proceedings of the IEEE, vol. 62, no. 6, pp. 769–770, Jun. 1974. doi:10.1109/PROC.1974.9547
> 3. C. L. Fortescue, "Ohm's Law in alternating current circuits," Proceedings of the IEEE, vol. 55, no. 11, pp. 1934–1936, Nov. 1967. doi:10.1109/PROC.1967.6033

As referências de livro parecem válidas – um livro sobre circuitos elétricos provavelmente teria informações sobre a lei de Ohm – mas, sem o número da página, essa citação não é útil para verificar as afirmações da prosa. Pior, ambas as citações de _Proceedings of the IEEE_ são completamente inventadas. Os DOIs levam a citações totalmente diferentes e têm outros problemas também. Por exemplo, [C. L. Fortescue](https://en.wikipedia.org/wiki/Charles_LeGeyt_Fortescue 'Charles LeGeyt Fortescue') estava morto havia mais de 30 anos na suposta época em que o texto foi escrito, e o Vol. 55, Edição 11 não lista nenhum artigo que corresponda a nada remotamente próximo da informação dada na referência 3.

### Uso incorreto ou não convencional de referências

Ferramentas de IA podem ter sido instruídas a incluir referências e tentar fazê-lo como a Wikipédia espera, mas falham em alguns detalhes-chave de implementação ou se destacam quando comparadas às convenções.

**Exemplos**

No exemplo abaixo, observe a tentativa incorreta de reutilizar referências. A ferramenta usada aqui não era capaz de pesquisar fontes não confabuladas (pois isso foi feito no dia anterior ao lançamento do Bing Deep Search), mas ainda assim encontrou uma referência real. A sintaxe para reutilizar as referências estava incorreta.

Neste caso, a fonte _Smith, R. J._ – sendo a "terceira fonte", a ferramenta presumivelmente gerou o link 'https://pubmed.ncbi.nlm.nih.gov/3' (que tem uma referência PMID igual a 3) – também é completamente irrelevante para o corpo do artigo. O usuário não verificou a referência antes de convertê-la em uma referência {{cite journal}}, embora os links resolvam.

O LLM, neste caso, incluiu diligentemente a sintaxe incorreta de reutilização após cada ponto final.

> For over thirty years, computers have been utilized in the rehabilitation of individuals with brain injuries. Initially, researchers delved into the potential of developing a "prosthetic memory."<ref>Fowler R, Hart J, Sheehan M. A prosthetic memory: an application of the prosthetic environment concept. _Rehabil Counseling Bull_. 1972;15:80–85.</ref> However, by the early 1980s, the focus shifted towards addressing brain dysfunction through repetitive practice.<ref>{{Cite journal |last=Smith |first=R. J. |last2=Bryant |first2=R. G. |date=1975-10-27 |title=Metal substitutions incarbonic anhydrase: a halide ion probe study |url=https://pubmed.ncbi.nlm.nih.gov/3 |journal=Biochemical and Biophysical Research Communications |volume=66 |issue=4 |pages=1281–1286 |doi=10.1016/0006-291x(75)90498-2 |issn=0006-291X |pmid=3}}</ref> Only a few psychologists were developing rehabilitation software for individuals with Traumatic Brain Injury (TBI), resulting in a scarcity of available programs.<sup>[3]</sup> Cognitive rehabilitation specialists opted for commercially available computer games that were visually appealing, engaging, repetitive, and entertaining, theorizing their potential remedial effects on neuropsychological dysfunction.<sup>[3]</sup>

Alguns LLMs ou interfaces de chatbot usam o caractere ↩ para indicar notas de rodapé:

> References
>
> Would you like help formatting and submitting this to Wikipedia, or do you plan to post it yourself? I can guide you step-by-step through that too.
>
> **Footnotes**
>
> 1.  KLAS Research. (2024). _Top Performing RCM Vendors 2024_. https://klasresearch.com ↩ ↩2
> 2.  PR Newswire. (2025, February 18). _CureMD AI Scribe Launch Announcement_. https://www.prnewswire.com/news-releases/curemd-ai-scribe ↩

### Parâmetros UTM específicos do ChatGPT

O ChatGPT pode adicionar o [parâmetro UTM](https://en.wikipedia.org/wiki/UTM_parameter 'UTM parameter') `utm_source=openai` ou, em edições anteriores a agosto de 2025, `utm_source=chatgpt.com` a URLs que está usando como fontes. Outros LLMs, como o Gemini ou o Claude, usam parâmetros UTM com menos frequência.[^13]

Observação: embora isso prove definitivamente o envolvimento do ChatGPT, não prova, por si só, que o ChatGPT também gerou a escrita. Alguns editores usam ferramentas de IA para encontrar citações para texto já existente; isso ficará aparente no histórico de edições.

**Exemplos**

> Following their marriage, Burgess and Graham settled in Cheshire, England, where Burgess serves as the head coach for the Warrington Wolves rugby league team. [https://www.theguardian.com/sport/2025/feb/11/sam-burgess-interview-warrington-rugby-league-luke-littler?utm_source=chatgpt.com]

> Vertex AI documentation and blog posts describe watermarking, verification workflow, and configurable safety filters (for example, person‑generation controls and safety thresholds). ([cloud.google.com](https://cloud.google.com/vertex-ai/generative-ai/docs/image/generate-images?utm_source=openai))

### Referências nomeadas declaradas na seção de referências mas não usadas no corpo do artigo

_Esta seção está vazia._ Você pode ajudar a completá-la. _(outubro de 2025)_

**Exemplos**

Veja estes diffs para exemplos. As referências problemáticas aparecem como erros de análise (parser) na lista de referências.

- [Special:PermanentLink/1287201002#References](https://en.wikipedia.org/wiki/Special:PermanentLink/1287201002#References 'Special:PermanentLink/1287201002')
- [Special:PermanentLink/1292432848#References](https://en.wikipedia.org/wiki/Special:PermanentLink/1292432848#References 'Special:PermanentLink/1292432848')
- [Special:PermanentLink/1291491974#References](https://en.wikipedia.org/wiki/Special:PermanentLink/1291491974#References 'Special:PermanentLink/1291491974')
- [Special:PermanentLink/1291561040#References](https://en.wikipedia.org/wiki/Special:PermanentLink/1291561040#References 'Special:PermanentLink/1291561040')

---

## Discrepâncias no estilo de escrita e na variedade de inglês

### Cortes abruptos

Ferramentas de IA podem parar abruptamente de gerar conteúdo, por exemplo, se preverem a sequência de fim de texto (que aparece como `<|endoftext|>`) a seguir. Além disso, o número de tokens que uma única resposta tem costuma ser limitado, e respostas adicionais exigem que o usuário selecione "continuar gerando".

Este método não é infalível, pois um copiar/colar malformado do computador local também pode causar isso. Também pode indicar uma violação de direitos autorais em vez do uso de um LLM.

### Mudança repentina no estilo de escrita

Uma mudança repentina no estilo de escrita de um editor, como uma gramática inesperadamente impecável em comparação com suas outras comunicações, pode indicar o uso de ferramentas de IA.

### Mudança repentina na variedade de inglês usada

Uma incompatibilidade entre a localização do usuário, os vínculos nacionais do tópico com uma variedade de inglês e a variedade de inglês usada pode indicar o uso de ferramentas de IA. Um autor humano da Índia escrevendo sobre uma universidade indiana provavelmente não usaria o inglês americano; no entanto, as saídas dos LLMs usam o inglês americano por padrão, a menos que sejam instruídas de outra forma.[^9] Observe que falantes não nativos de inglês tendem a misturar variedades de inglês, e tais sinais só devem levantar suspeita se houver uma mudança repentina e completa no uso da variedade de inglês de um editor.

### Resumos de edição excessivamente verbosos

[Resumos de edição](https://en.wikipedia.org/wiki/Help:Edit_summary 'Help:Edit summary') gerados por IA costumam ser excepcionalmente longos, escritos como parágrafos formais em primeira pessoa sem abreviações, e/ou itemizam de forma conspícua as convenções da Wikipédia.

> Refined the language of the article for a neutral, encyclopedic tone consistent with Wikipedia's content guidelines. Removed promotional wording, ensured factual accuracy, and maintained a clear, well-structured presentation. Updated sections on history, coverage, challenges, and recognition for clarity and relevance. Added proper formatting and categorized the entry accordingly

> I formalized the tone, clarified technical content, ensured neutrality, and indicated citation needs. Historical narratives were streamlined, allocation details specified with regulatory references, propagation explanations made reader-friendly, and equipment discussions focused on availability and regulatory compliance, all while adhering to encyclopedic standards.

> **Concise edit summary:** Improved clarity, flow, and readability of the plot section; reduced redundancy and refined tone for better encyclopedic style.

### "Declarações de submissão" em rascunhos do AFC

Este é específico de rascunhos submetidos pelo Articles for Creation. Pelo menos um LLM tende a inserir "declarações de submissão" supostamente destinadas aos revisores, que supostamente explicam por que o assunto é notável e por que o rascunho atende às diretrizes da Wikipédia. É claro que tudo o que isso de fato faz é informar aos revisores que o rascunho foi gerado por LLM e que deve ser recusado ou eliminado rapidamente, sem pensar duas vezes.

> Reviewer note (for AfC): This draft is a neutral and well-sourced biography of Portuguese public manager Jorge Patrão. All references are from independent, reliable sources (Público, Diário de Notícias, Jornal de Negócios, RTP, O Interior, Agência Lusa) covering his public career and cultural activity. It meets WP:RS and WP:BLP standards and demonstrates clear notability per WP:NBIO through: – Presidency of Serra da Estrela Tourism Region (1998–2013); – Presidency of Parkurbis – Covilhã Science and Technology Park; – Founding role in Rede de Judiarias de Portugal (member of the Council of Europe's European Routes of Jewish Heritage); – Authorship of the book "1677 – A Fábrica d'El-Rei"; – Founder/curator of the Beatriz de Luna Art Collection (Old Master focus). There is also a Portuguese version of this article at pt.wikipedia.org/wiki/Jorge_Patrão. Thank you for your review. -->

— Encontrado no topo do Draft:Jorge Patrão (todos os inevitáveis erros de formatação estão presentes no original)

### Predefinições de revisão do AFC pré-recusadas

Ocasionalmente, um novo editor cria um rascunho que inclui uma predefinição de revisão do AFC já definida como "recusado". A predefinição também é desprovida de conteúdo, sem nenhuma justificativa do revisor. O LLM aparentemente se oferece para adicionar uma predefinição de submissão do AFC ao rascunho e então fornece algo como `{{AfC submission|d}}`, no qual o parâmetro "d" pré-recusa o rascunho ao substituir por {{AfC submission/declined}}. O histórico de contribuições do rascunho revela que esse modelo foi inserido em algum momento pelo criador do rascunho. Invariavelmente, o criador então pergunta no Wikipedia:WikiProject Articles for creation/Help desk ou em uma das outras páginas de ajuda por que o rascunho foi recusado sem nenhum feedback. A presença de um cabeçalho "submissão recusada" sem conteúdo é um indicador **forte** de que o rascunho foi gerado por LLM.

---

## Sinais de escrita humana

### Idade do texto em relação ao lançamento do ChatGPT

O ChatGPT foi lançado ao público em 30 de novembro de 2022. Embora a OpenAI tivesse LLMs igualmente poderosos antes disso, eles eram serviços pagos e não facilmente acessíveis ou conhecidos por leigos. O ChatGPT teve crescimento extremo imediatamente após o lançamento.

É muito improvável que qualquer texto específico adicionado à Wikipédia **antes de 30 de novembro de 2022** tenha sido gerado por um LLM. Se uma edição foi feita antes dessa data, o uso de IA pode ser descartado com segurança para aquela revisão. Embora algum texto mais antigo possa exibir alguns dos sinais de IA dados nesta lista, e até parecer convincentemente ter sido gerado por IA, a vastidão da Wikipédia abre espaço para essas raras coincidências.

### Capacidade de explicar as próprias escolhas editoriais

Os editores devem ser capazes de explicar por que fizeram uma ou mais edições ou cometeram erros. Por exemplo, se um editor insere uma URL que parece fabricada, você pode perguntar como a confusão ocorreu em vez de tirar conclusões precipitadas. Se ele conseguir fornecer o link correto e explicá-lo como um erro humano (talvez um erro de digitação), ou compartilhar a passagem relevante da fonte real, isso aponta para um erro humano comum.

---

## Indicadores ineficazes

Acusações falsas de uso de IA podem [afastar novos editores](https://en.wikipedia.org/wiki/Wikipedia:BITE 'Wikipedia:BITE') e fomentar uma atmosfera de suspeita. Antes de alegar que IA foi usada, considere se o [efeito Dunning–Kruger](https://en.wikipedia.org/wiki/Dunning%E2%80%93Kruger_effect 'Dunning–Kruger effect') e o [viés de confirmação](https://en.wikipedia.org/wiki/Confirmation_bias 'Confirmation bias') estão obscurecendo seu julgamento. Aqui estão vários indicadores razoavelmente comuns que são ineficazes na detecção de LLM — e podem até indicar o oposto.

- **Gramática perfeita**: embora os LLMs modernos sejam conhecidos por sua alta proficiência gramatical, muitos editores também são escritores habilidosos ou vêm de carreiras profissionais de escrita. (Veja também [§ Discrepâncias no estilo de escrita e na variedade de inglês](#discrepâncias-no-estilo-de-escrita-e-na-variedade-de-inglês).)

- **Prosa "sem graça" ou "robótica"**: por padrão, os LLMs modernos tendem a uma prosa efusiva e prolixa, como detalhado acima; embora essa tendência seja formulaica, ela pode não soar como "robótica" para quem não está familiarizado com a escrita de IA.[^14]

- **Palavras "rebuscadas", "acadêmicas" ou incomuns**: embora os LLMs favoreçam desproporcionalmente certas palavras e frases, muitas das quais longas e com índices de legibilidade difíceis, a correlação não se estende a _toda_ prosa "rebuscada", acadêmica ou de aparência "avançada".[^1] Palavras de baixa frequência e "incomuns" também têm menor probabilidade de aparecer na escrita gerada por IA, pois são estatisticamente menos comuns, a menos que sejam nomes próprios diretamente relacionados ao tópico.

- **Escrita em estilo de carta (isoladamente)**: embora muitas mensagens de página de discussão escritas com saudações, despedidas, linhas de assunto e outras formalidades depois de 2023 tendam a parecer geradas por IA, cartas e e-mails têm sido convencionalmente escritos dessa forma _muito_ antes de os LLMs modernos existirem. Editores humanos (particularmente os mais novos) podem formatar seus comentários de página de discussão de maneira semelhante por vários motivos, como estarem mais acostumados à comunicação formal, postarem como parte de um trabalho escolar que exige isso, ou simplesmente confundirem a página de discussão com um e-mail. Mensagens de página de discussão geradas por IA tendem a ter outros indícios, como listas verticais,[^d] textos de preenchimento ou cortes abruptos.

- **Conjunções (isoladamente)**: embora os LLMs tendam a usar em excesso palavras e expressões de ligação de maneira artificial e formulaica que implica síntese inadequada de fatos, tais usos são típicos da escrita dissertativa por humanos e não são indicadores fortes por si sós.

- **Wikitext bizarro**: embora os LLMs possam alucinar predefinições ou gerar código wikitext com sintaxe inválida pelos motivos explicados em [§Uso de Markdown](#uso-de-markdown), é improvável que gerem conteúdo com certos erros e artefatos de aparência aleatória e "inexplicável" (excluindo os listados nesta página em [§Marcação](#marcação-markup)). Tags HTML colocadas de forma bizarra, como `<span>`, são mais indicativas de extensões de navegador mal programadas ou de um bug conhecido da ferramenta de tradução de conteúdo da Wikipédia (T113137). Sintaxe deslocada como `''Catch-22 i''s a satirical novel.` (renderizada como "_Catch-22 i_ s a satirical novel.") é mais indicativa de erros no VisualEditor, onde tais erros são mais difíceis de notar do que na edição de código-fonte.

---

## Notas

[^a]: não é exclusivo dos chatbots de IA; é produzido pela predefinição {{as of}}

[^b]: Exemplo de `Would you like me to ... turn this into actual Wikipedia markup format (wikitext)?` em um rascunho excluído (apenas administradores)

[^c]: Exemplo de ` ```wikitext ` em um rascunho.

[^d]: Exemplo de uma lista vertical em uma discussão de eliminação

---

## Referências

[^1]: Russell, Jenna; Karpinska, Marzena; Iyyer, Mohit (2025). [_People who frequently use ChatGPT for writing tasks are accurate and robust detectors of AI-generated text_](https://aclanthology.org/2025.acl-long.267/). Proceedings of the 63rd Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers). Vienna, Austria: Association for Computational Linguistics. pp.5342–5373. arXiv:[2501.15654](https://arxiv.org/abs/2501.15654).

[^2]: Dugan, Liam; Hwang, Alyssa; Trhlik, Filip; Zhu, Andrew; Ludan, Josh Magnus; Xu, Hainiu; Ippolito, Daphne; Callison-Burch, Chris (2024). [_RAID: A Shared Benchmark for Robust Evaluation of Machine-Generated Text Detectors_](https://aclanthology.org/2024.acl-long.674). Proceedings of the 62nd Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers). Bangkok, Thailand: Association for Computational Linguistics. pp.12463–12492. arXiv:[2405.07940](https://arxiv.org/abs/2405.07940).

[^3]: ["People who frequently use ChatGPT for writing tasks are accurate and robust detectors of AI-generated text"](https://arxiv.org/html/2501.15654v2). _arxiv.org_. Retrieved 2025-11-28.

[^4]: This can be directly observed by examining images generated by text-to-image models; they look acceptable at first glance, but specific details tend to be blurry and malformed. This is especially true for background objects and text.

[^5]: ["10 Ways AI Is Ruining Your Students' Writing"](https://www.chronicle.com/article/10-ways-ai-is-ruining-your-students-writing). _Chronicle of Higher Education_. September 16, 2025. Archived from the original on October 1, 2025. Retrieved October 1, 2025.

[^6]: Juzek, Tom S.; Ward, Zina B. (2025). [_Why Does ChatGPT "Delve" So Much? Exploring the Sources of Lexical Overrepresentation in Large Language Models_](https://aclanthology.org/2025.coling-main.426.pdf) (PDF). Findings of the Association for Computational Linguistics: ACL 2025. Association for Computational Linguistics. arXiv:[2412.11385](https://arxiv.org/abs/2412.11385).

[^7]: Reinhart, Alex; Markey, Ben; Laudenbach, Michael; Pantusen, Kachatad; Yurko, Ronald; Weinberg, Gordon; Brown, David West. ["Do LLMs write like humans? Variation in grammatical and rhetorical styles"](http://arxiv.org/abs/2410.16107). Retrieved 4 December 2025.

[^8]: Kobak, Dmitry; González-Márquez, Rita; Horvát, Emőke-Ágnes; Lause, Jan (2 July 2025). ["Delving into LLM-assisted writing in biomedical publications through excess vocabulary"](https://www.science.org/doi/10.1126/sciadv.adt3813). _Science Advances_. **11** (27). doi:[10.1126/sciadv.adt3813](https://doi.org/10.1126%2Fsciadv.adt3813). ISSN 2375-2548. PMC 12219543. PMID 40009654.

[^9]: Ju, Da; Blix, Hagen; Williams, Adina (2025). [_Domain Regeneration: How well do LLMs match syntactic properties of text domains?_](https://aclanthology.org/2025.findings-acl.120). Findings of the Association for Computational Linguistics: ACL 2025. Vienna, Austria: Association for Computational Linguistics. pp.2367–2388. arXiv:[2505.07784](https://arxiv.org/abs/2505.07784). doi:[10.18653/v1/2025.findings-acl.120](https://doi.org/10.18653%2Fv1%2F2025.findings-acl.120).

[^10]: Kousha, Kayvan; Thelwall, Mike (2025). [_How much are LLMs changing the language of academic papers after ChatGPT? A multi-database and full text analysis_](https://arxiv.org/pdf/2509.09596). ISSI 2025 Conference. arXiv:[2509.09596](https://arxiv.org/abs/2509.09596).

[^11]: Merrill, Jeremy B.; Chen, Szu Yu; Kumer, Emma (13 November 2025). ["What are the clues that ChatGPT wrote something? We analyzed its style"](https://www.washingtonpost.com/technology/interactive/2025/how-detect-chatgpt-em-dash/). _The Washington Post_. Retrieved 14 November 2025.

[^12]: ["Unproductive Interpretation of Work and Employment as Misinformation?"](https://www.laetusinpraesens.org/docs20s/workeco.php). Archived from the original on 2 September 2025. Retrieved 21 October 2025.

[^13]: See [T387903](https://phabricator.wikimedia.org/T387903 'phabricator:T387903').

[^14]: Murray, Nathan; Tersigni, Elisa (21 July 2024). ["Can instructors detect AI-generated papers? Postsecondary writing instructor knowledge and perceptions of AI"](https://journals.sfu.ca/jalt/index.php/jalt/article/view/1895). _Journal of Applied Learning & Teaching_. **7** (2). doi:[10.37074/jalt.2024.7.2.12](https://doi.org/10.37074%2Fjalt.2024.7.2.12). ISSN 2591-801X. Retrieved 21 November 2025.
