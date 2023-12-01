---
title: "Comment se faire vacciner au Quebec"
author: "Prune"
date: 2021-04-29T21:05:54.543Z
lastmod: 2023-11-30T22:23:39-05:00

description: ""

subtitle: "Il y a deux semaines le Quebec a ouvert la vaccination aux personnes de 45 ans et plus, avec le vaccin AstraZeneca."

image: "/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/1.png" 
images:
 - "/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/1.png"
 - "/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/2.png"
 - "/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/3.png"
 - "/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/4.png"
 - "/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/5.png"
 - "/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/6.png"


aliases:
    - "/comment-se-faire-vacciner-au-quebec-c3f7c09aaf6d"

---

![image](/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/1.png#layoutTextWidth)
Il y a deux semaines le Quebec a ouvert la vaccination aux personnes de 45 ans et plus, avec le vaccin AstraZeneca.

Apres plusieurs essais, IMPOSSIBLE d’avoir une place. Impossible de remplir le formulaire assez vite.

Un ami a donc crée un bot pour être le plus rapide. Voila comment.

### Disclamer

Cette publication est faite à titre purement informatif et éducatif.   
C’est une analyse du fonctionnement du site de reservation de vaccin faite uniquement avec les outils qui se trouvent dans tous les navigateurs.

Aucune informations autres que celles publiquement disponibles n’est divulguée.

Je n’encourage personne à répliquer ce qui est fait ici ni à utiliser les informations contenuent dans ce post pour attaquer ou harceller le site de reservation.

Je ne saurais en aucun cas etre tenu responsable d’un quelconque agissement des lecteurs. Si cela ne vous convient pas, arrêtez de lire immédiatement.

### La procedure standard

Elle est plutôt simple:

*   aller sur le site [https://portal3.clicsante.ca/](https://portal3.clicsante.ca/)
*   entrer son code postal
*   sélectionner un centre de vaccin ou une pharmacie
![image](/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/2.png#layoutTextWidth)


*   sélectionner la date souhaité (en general, on a pas le choix), puis l’heure
![image](/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/3.png#layoutTextWidth)


*   remplir un lonnnng formulaire, ce qui prend en general au moins 30s si vous tapez vite, voir plus
![image](/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/4.png#layoutTextWidth)


Note: votre No d’assurance maladie, c’est **PAS VOTRE N.A.S**, mais le code en bas de votre carte soleil, qui commence par les 3 lettres de votre nom et la 1ere lettre de votre prénom, puis votre age (ex: FOOJ 740712..)

En general quand vous en êtes la, vous cliquez sur “SOUMETTRE” en bas de page et ca vous dit que votre choix n’est plus disponible.

![image](/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/5.png#layoutTextWidth)


### 2eme tentative

Vous recommencez le process du debut, et encore une fois, le temps de remplir le formulaire, votre place n’est plus dispo…

![image](/content/posts/2021-04-29_comment-se-faire-vacciner-au-quebec/images/6.png#layoutTextWidth)


Voila pourquoi, quand vous réservez une place de spectacle sur TicketMaster™ ou autres, on vous laisse un gros 5 minutes pour finaliser votre transaction. Pendent ce temps la, votre place est bloquée et on ne peut pas vous la prendre. Passé les 5 minutes, elle revient dans le pool.

Mais bon, ca demande un peu plus de travail. J’imagine que le ministère de la santé ne pensait pas que le monde se battrait pour avoir le vaccin… Ou ils ont sous-traités, a fort prix, sans se préoccuper de l’experience utilisateur ?

### Décomposition

Un “Ingenieur Informatique” comme moi ne peux pas se laisser faire comme ca par des ordinateurs !

Et je ne suis pas le seul dans ce cas la.

C’est un ami que je ne nommerais pas, appelons le **Emmanuel** pour la suite de l’histoire, qui est arrivé avec une solution. Il a fais un bout de code en [Go](https://go.dev/) pour scanner le site de vaccination. Une sorte de bot qui, a chaque execution, donne la liste des lieux ou se faire vacciner. Donc, en le lançant toutes les 10 secondes, on a une info fraiche et rapide. Il ne reste ensuite plus qu’a clicker sur le lien pour ouvrir la page dans le navigateur et… remplir le maudit formulaire (on y reviendra).

Donc, comment fonctionne le site de reservation de vaccination ?

Comme beaucoup de sites de nos jours, c’est une single page application (SPA) et une API REST. On va donc la détailler.

#### Pre-requis

Le site vous demande votre code-postal.

En cachette, il vous cree aussi une “clé d’authentification”, un Token comme on dit. Dans notre cas, il est possible de le récupérer en allant sur le site et en utilisant la fonction “Inspection” pour regarder les headers de communication de la requête:
`authorization: Basic cHVibGljQHRyaW1vei5jb206MTIzNDU2Nzgh`

En general le Token est propre a chaque utilisateur et il faut donc le passer a chaque requête sur le site. Votre navigateur fait ca pour vous.

Ce Token est un message encodé en Base64, un format compatible avec le web et ne contenant pas de caractères spéciaux.

Dans notre cas, on peut voir le contenu reel du token:
`echo cHVibGljQHRyaW1vei5jb206MTIzNDU2Nzgh |base64 -D``[public@trimoz.com](mailto:public@trimoz.com):12345678!`

Surprise: le Token est le meme pour tout le monde, et semble contenir le nom du “produit” (le site web):

[http://trimoz.com](http://trimoz.com) -&gt; [https://clichealth.net/](https://clichealth.net/) -&gt; [https://emsolutions.ca/](https://emsolutions.ca/)

Bref, meme si ce n’est pas grave et que ce site ne contient (pour le moment) aucune donnée sensible, je dis un grand bravo au(x) champion(s) qui ont fait ca.   
En tout cas moi j’ai ri.   
C’est sympa pour nous, car du coup on peut le mettre “en dur” dans notre bot.

Donc, une fois qu’on a le code-postal et le Token, on peut commencer à taper dans l’API du site.

#### Geocoding

Le site vous présente la liste des lieux de vaccination les plus proches. Il utilise donc votre code postal pour définir le centre de la zone de recherche. Pour faire simple, il utilise vos coordonnées GPS et une bounding-box.

Le 1er appel est donc l’API de geocoding:
`GET https://api3.clicsante.ca/v3/geocode?address=h1a0a1``{  
  &#34;**results**&#34;: [  
    {  
      &#34;address_components&#34;: [  
        {  
          &#34;long_name&#34;: &#34;H1A 0A1&#34;,  
          &#34;short_name&#34;: &#34;H1A 0A1&#34;,  
          &#34;types&#34;: [  
            &#34;postal_code&#34;  
          ]  
        },  
        {  
          &#34;long_name&#34;: &#34;Riviere-des-Prairies—Pointe-aux-Trembles&#34;,  
          &#34;short_name&#34;: &#34;Riviere-des-Prairies—Pointe-aux-Trembles&#34;,  
          &#34;types&#34;: [  
            &#34;political&#34;,  
            &#34;sublocality&#34;,  
            &#34;sublocality_level_1&#34;  
          ]  
        },  
        {  
          &#34;long_name&#34;: &#34;Montreal&#34;,  
          &#34;short_name&#34;: &#34;Montreal&#34;,  
          &#34;types&#34;: [  
            &#34;locality&#34;,  
            &#34;political&#34;  
          ]  
        },  
        {  
          &#34;long_name&#34;: &#34;Montreal&#34;,  
          &#34;short_name&#34;: &#34;Montreal&#34;,  
          &#34;types&#34;: [  
            &#34;administrative_area_level_2&#34;,  
            &#34;political&#34;  
          ]  
        },  
        {  
          &#34;long_name&#34;: &#34;Quebec&#34;,  
          &#34;short_name&#34;: &#34;QC&#34;,  
          &#34;types&#34;: [  
            &#34;administrative_area_level_1&#34;,  
            &#34;political&#34;  
          ]  
        },  
        {  
          &#34;long_name&#34;: &#34;Canada&#34;,  
          &#34;short_name&#34;: &#34;CA&#34;,  
          &#34;types&#34;: [  
            &#34;country&#34;,  
            &#34;political&#34;  
          ]  
        }  
      ],  
      &#34;formatted_address&#34;: &#34;Montreal, QC H1A 0A1, Canada&#34;,  
      &#34;**geometry**&#34;: {  
        &#34;bounds&#34;: {  
          &#34;northeast&#34;: {  
            &#34;lat&#34;: 45.652886,  
            &#34;lng&#34;: -73.5001424  
          },  
          &#34;southwest&#34;: {  
            &#34;lat&#34;: 45.6519153,  
            &#34;lng&#34;: -73.50257289999999  
          }  
        },  
        &#34;**location**&#34;: {  
          &#34;lat&#34;: 45.6524306,  
          &#34;lng&#34;: -73.5012086  
        },  
        &#34;location_type&#34;: &#34;APPROXIMATE&#34;,  
        &#34;viewport&#34;: {  
          &#34;northeast&#34;: {  
            &#34;lat&#34;: 45.65374963029149,  
            &#34;lng&#34;: -73.50000866970849  
          },  
          &#34;southwest&#34;: {  
            &#34;lat&#34;: 45.65105166970849,  
            &#34;lng&#34;: -73.5027066302915  
          }  
        }  
      },  
      &#34;place_id&#34;: &#34;ChIJA91J-y_iyEwRvgm6PIfurds&#34;,  
      &#34;types&#34;: [  
        &#34;postal_code&#34;  
      ]  
    }  
  ],  
  &#34;status&#34;: &#34;OK&#34;  
}`

Nous avons besoin de **results[0].geometry.location** pour faire notre recherche.

#### La recherche

La, ça se complique. On va décortiquer l’URL:
`GET https://api3.clicsante.ca/v3/availabilities?dateStart=2021-04-29&amp;dateStop=2021-08-27&amp;latitude=45.6524306&amp;longitude=-73.5012086&amp;maxDistance=1000&amp;serviceUnified=237&amp;postalCode=H1A%200A1&amp;page=0`

*   [https://api3.clicsante.ca/v3/availabilities](https://api3.clicsante.ca/v3/availabilities?) 
ca c’est le endpoint
*   **dateStart**=2021–04–29
OK, ca c’est aujourd’hui
*   **dateStop**=2021–08-27
Ca c’est… dans 1 mois
*   **latitude**=45.6524306&amp;**longitude**=-73.5012086
Ah, voila les coord GPS !
*   **maxDistance**=1000
C’est le rayon du cercle, en Kilometres. Qui veut prendre un rendez-vous au Havre-Saint-Pierre ? Je l’ai réduit à 10KM pour Montreal, mais 30KM est préférable dans la région de Quebec/Levis si vous voulez un rdv rapidement
*   **serviceUnified**=237
Ca, je sais pas trop, mais ca change jamais
*   **postalCode**=H1A%200A1
Le code postal, avec un espace entre les 2 champs, encodé en HTML. Dans le bot on le passe sans espace et ca fonctionne aussi, heureusement
*   **page**=0
Ca c’est la petite nouveauté, il me semble: la recherche est paginée. On va voir plus tard comment ca marche.

La réponse est encore un gros JSON (que je simplifie ici) :
`{  
  &#34;establishments&#34;: [  
    {  
      &#34;id&#34;: 60093,  
      &#34;name&#34;: &#34;CIUSSS de lEst-de-lÎle-de-Montréal  - Centre Machin- Citoyens - Vaccin COVID-19&#34;,  
      &#34;phone&#34;: &#34;&#34;,  
      &#34;address&#34;: &#34;125 Rue Notre-Dame Est, Pointe-aux-Trembles, QC H2B 2Y2&#34;,  
      &#34;public_url&#34;: &#34;[https://clients3.clicsante.ca/60093](https://clients3.clicsante.ca/60093)&#34;  
    },  
    {  
      &#34;id&#34;: 61047,  
      &#34;name&#34;: &#34;Accès Pharma/Wal-Mart - Jean  Le Tong Le pharmaciennes SENC - Vaccin COVID-19 Citoyen&#34;,  
      &#34;phone&#34;: &#34;(514) 555-6505&#34;,  
      &#34;address&#34;: &#34;126, SHERBROOKE, POINTE-AUX-TREMBLES, H2A 2V9&#34;,  
      &#34;public_url&#34;: &#34;[https://clients3.clicsante.ca/61047](https://clients3.clicsante.ca/61047)&#34;  
    },  
  ],  
  &#34;places&#34;: [  
    {  
      &#34;id&#34;: 6062,  
      &#34;establishment&#34;: 73215,  
      &#34;name_fr&#34;: &#34;Jean Messier - AstraZeneca&#34;,  
      &#34;name_en&#34;: &#34;Jean Messier - AstraZeneca&#34;,  
      &#34;formatted_address&#34;: &#34;100, BOUL. SAINT-JEAN-BAPTISTE, POINTE-AUX-TREMBLES, H2B 2A5&#34;,  
      &#34;latitude&#34;: 45.2414221,  
      &#34;longitude&#34;: -73.2026806,  
      &#34;is_virtual&#34;: 0,  
      &#34;availabilities&#34;: {  
        &#34;su237&#34;: {  
          &#34;t07&#34;: 255,  
          &#34;ta7&#34;: 0  
        }  
      }  
    },  
    {  
      &#34;id&#34;: 2017,  
      &#34;establishment&#34;: 60093,  
      &#34;name_fr&#34;: &#34;Centre Rouseay&#34;,  
      &#34;name_en&#34;: &#34;Centre Rouseay&#34;,  
      &#34;formatted_address&#34;: &#34;121 Rue Notre-Dame Est Montréal H2B2Y4 Canada&#34;,  
      &#34;latitude&#34;: 45.6409872,  
      &#34;longitude&#34;: -73.4902212,  
      &#34;is_virtual&#34;: 0,  
      &#34;availabilities&#34;: {  
        &#34;su237&#34;: {  
          &#34;t07&#34;: 2520,  
          &#34;ta7&#34;: 54745  
        }  
      }  
    },  
  ],  
  &#34;distanceByPlaces&#34;: {  
    &#34;3357&#34;: 1,  
    &#34;3168&#34;: 1,  
    &#34;6062&#34;: 1,  
    &#34;3390&#34;: 2,  
    &#34;3381&#34;: 2,  
    &#34;6688&#34;: 2,  
    &#34;6182&#34;: 2,  
    &#34;3427&#34;: 2,  
    &#34;3174&#34;: 2,  
    &#34;6301&#34;: 2,  
    &#34;2017&#34;: 2,  
    &#34;4373&#34;: 6,  
    &#34;3812&#34;: 6,  
    &#34;3770&#34;: 6,  
    &#34;4349&#34;: 6  
  },  
  &#34;serviceIdsByPlaces&#34;: []  
}`

Donc on a:

*   des **établissements** qui offrent la vaccination
*   des **places** ou chaque établissement dispense la vaccination
*   la **distance**
*   le type de **service** pour chaque place.
Depuis une semaine ce champs est vide. Pour avoir la liste des services il faut maintenant faire une nouvelle requête (a suivre). C’est un des changements que j’ai apporté au bot d’**Emmanuel**.

#### Pagination

Comme on a pu le voir, l’URL comporte un paramètre `page=0`. Ca c’est nouveau par rapport au bot d’**Emmanuel** de la semaine dernière. Il faut donc faire une requête sur `page=1`, `page=2` , etc.

Quand on est sur le site, c’est le javascript qui s’occupe de faire une nouvelle requête quand on scroll la page jusqu’en bas.

Dans le bot, j’ai donc ajouté une boucle `for` qui incrémente le numero de page. Quand il n’y a plus de donnée le site répond avec un code `204` au lieu du standard `200 OK`
`// on commence a la page 0  
nextPage := 0``// on entre dans la boucle  
for {``// on cree l&#39;URL pour la page courante  
req, err := newGetRequest(fmt.Sprintf(&#34;%s&amp;page=%d&#34;, url, nextPage))  
  if err != nil {  
   return err  
  }``// on execute la requete HTTP  
resp, err := http.DefaultClient.Do(req)  
  if err != nil {  
   return err  
  }``// so on recoit un code 204, on arrete  
if resp.StatusCode != 200 {  
   fmt.Printf(&#34;done\n, &#34;)  
   resp.Body.Close()  
   break  
  }  
...`

#### Filtrage

Une requête sur Montreal peut facilement donner 8 a 16 pages, car ce sont tous les lieux a proximité sans regarder si il y a de la place ou pas.

Heureusement pour nous, enfin, pour mon ami **Emmanuel** et moi, qui sommes des 45+ et qui ne peuvent recevoir QUE le AstraZeneca, tous les lieux compatibles sont suffixés avec `— AstraZeneca` . On peut donc facilement éliminer les lieux indésirables de la liste.

Il y a aussi un champs “availabilities” dans les **Places**, qui semble indiquer la dispo mais pas si c’est du AstraZeneca… donc on ne l’utilise pas pour le moment.

#### Service

Chaque `etablissement` a son propre numero de `service` . On doit donc faire une nouvelle requête pour chaque:
`GET https://api3.clicsante.ca/v3/establishments/73215/services``[  
  {  
    &#34;id&#34;: 6563,  
    &#34;establishment&#34;: 73215,  
    &#34;service_template&#34;: {  
      &#34;id&#34;: 159,  
      &#34;name&#34;: &#34;1st_dose_COVID_19_vaccine_astrazeneca&#34;,  
      &#34;descriptionFr&#34;: &#34;1ère dose - Vaccin contre la COVID-19 - AstraZeneca&#34;,  
      &#34;descriptionEn&#34;: &#34;1st dose - COVID-19 vaccine AstraZeneca&#34;  
    },  
    &#34;module&#34;: 20,  
    &#34;name_fr&#34;: &#34;AstraZeneca - 1ère dose - Vaccin contre la COVID-19&#34;,  
    &#34;name_en&#34;: &#34;AstraZeneca - 1st dose - COVID-19 vaccine&#34;,  
    &#34;description_fr&#34;: &#34;&lt;p&gt;Vaccin contre la COVID-19 - AstraZeneca.&lt;/p&gt;&#34;,  
    &#34;description_en&#34;: &#34;&lt;p&gt;COVID-19 Vaccine - AstraZeneca.&lt;/p&gt;&#34;,  
    &#34;enable_personal_description&#34;: true,  
    &#34;length&#34;: 5,  
    &#34;interval&#34;: 5,  
    &#34;document_fr&#34;: &#34;&#34;,  
    &#34;document_en&#34;: &#34;&#34;,  
    &#34;price&#34;: 0,  
    &#34;price_description_fr&#34;: &#34;&#34;,  
    &#34;price_description_en&#34;: &#34;&#34;,  
...`

La seule chose qui nous concerne c’est le `id: 6563`du debut. Le reste semble être la config et le message d’alerte a afficher lorsque la page s’ouvre.

#### Dispo

Maintenant qu’on a une liste épurée, on peut valider si le site a de la place, et quand:
`GET https://api3.clicsante.ca/v3/establishments/73215/schedules/public?dateStart=2021-04-27&amp;dateStop=2021-05-30&amp;service=6563&amp;timezone=America/Toronto&amp;places=60626&amp;filter1=1&amp;filter2=0``{  
  &#34;availabilities&#34;: [  
    &#34;2021-05-04&#34;,  
    &#34;2021-05-05&#34;  
  ],  
  &#34;daysComplete&#34;: [],  
  &#34;upcomingAvailabilities&#34;: [],  
  &#34;pastAvailabilities&#34;: []  
}`

On a donc de la place le 4 et le 5 mai.

On peut donc afficher les URLs pour rapidement joindre le site de reservation sans se taper toute la recherche.

L’URL ressemble a:
`https://clients3.clicsante.ca/&lt;etablissement_id&gt;/take-appt?unifiedService=237&amp;portalPlace=&lt;place_id&gt;&amp;portalPostalCode=G6J%201Y7&amp;lang=fr`

Voila un exemple de ce que retourne le bot d’**Emmanuel**:
`go run covid.go  -postal-code H1A0A1 -distance 10``gathering page 0, 1, 2, 3, done  
Parsed 36 places in total``Name: Jean Messier - AstraZeneca  
  Address: 5500, BOUL. SAINT-JEAN-BAPTISTE, POINTE-AUX-TREMBLES, H2B 2A2  
  Distance: 1Km  
  Available: [2021-05-04 2021-05-05]  
  Upcoming: []  
  Rendez-vous: [https://clients3.clicsante.ca/73215/take-appt?unifiedService=237&amp;portalPlace=6062&amp;portalPostalCode=G6J%201Y7&amp;lang=fr](https://clients3.clicsante.ca/73215/take-appt?unifiedService=237&amp;portalPlace=6062&amp;portalPostalCode=G6J%201Y7&amp;lang=fr)``Name: Centre Machin- AstraZeneca  
  Address: 12 Rue Notre-Dame Est Montréal H2B2Y2 Canada  
  Distance: 2Km  
  Available: [2021-04-29 2021-04-30]  
  Upcoming: []  
  Rendez-vous: [https://clients3.clicsante.ca/70021/take-appt?unifiedService=237&amp;portalPlace=6301&amp;portalPostalCode=G6J%201Y7&amp;lang=fr](https://clients3.clicsante.ca/70021/take-appt?unifiedService=237&amp;portalPlace=6301&amp;portalPostalCode=G6J%201Y7&amp;lang=fr)`

#### Loop

En lançant le bot dans une boucle, on peut verifier la dispo presque en temps reel:
`while true ; do date ; go run covid.go  -postal-code H1A0A1 -distance 10 ; sleep 10 ; done`

Mais dépêchez-vous… tant que la même place re-apparait toutes les 10 secondes, c’est que la place est encore dispo, mais des quelle part, c’est perdu, meme si vous avez presque fini de remplir la page.

### Autofill

J’ai bien essayé de faire un bout de javascript pour remplir les champs du formulaire, mais bon, tous ces trucs en react avec un DOM dynamique… Pi j’ai une vie, et un metier aussi…  
On ne peut pas non plus tout automatiser car if y a un re-captcha à la fin de la page, justement pour nous empêcher d’utiliser un bot. C’est con, on aurait pu reserver tous les slots et les revendre sur eBay, comme le font les scalpers avec les concerts 😐  
Restons serieux.   
Donc, votre navigateur a lui meme une fonction qui permet de pre-remplir les champs de formulaires. Malheureusement dans ce cas, il ne fonctionne pas car les champs ont un nom dynamique.

L’extension `[autofill](https://addons.mozilla.org/en-CA/firefox/addon/autofill-quantum/)` pour Firefox et un peu plus configurable. Elle permet de définir précisément comment reconnaitre chaque champs du formulaire.  
Ici, on utilise `clients3.clicsante.ca/.*/take-appt` ce qui a pour effet de matcher les champs meme si la clé dynamique change.

Voila la config que j’ai utilisé. Attention de bien respecter une majuscule pour les noms et les autres formatages spéciaux:
`### AUTOFILL RULES ###,,,,,,  
Rule ID,Type,Name,Value,Site,Mode,Profile  
r1,0,&#34;^first_name$&#34;,&#34;Change_me&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r2,0,&#34;^last_name$&#34;,&#34;Change_me&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r3,0,&#34;^email$&#34;,&#34;[change_me@ici.net](mailto:change_me@ici.net)&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r4,0,&#34;^Confirmation du courriel$&#34;,&#34;[change_me@ici.net](mailto:change_me@ici.net)&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r5,0,&#34;^phone$&#34;,&#34;(123) 456 - 1234&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r6,0,&#34;^cellphone$&#34;,&#34;(123) 456 - 1234&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r7,0,&#34;^nam$&#34;,&#34;ABCD 7504 2110&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r8,0,&#34;^mother_first_name$&#34;,&#34;Change_me&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r9,0,&#34;^mother_last_name$&#34;,&#34;Change_me&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r10,0,&#34;^father_first_name$&#34;,&#34;Change_me&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r11,0,&#34;^father_last_name$&#34;,&#34;Change_me&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r12,3,&#34;^v-radio-243$&#34;,&#34;010&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r13,3,&#34;^v-radio-253$&#34;,&#34;010&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r14,3,&#34;^v-radio-263$&#34;,&#34;010&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r15,3,&#34;^v-radio-273$&#34;,&#34;010&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r16,3,&#34;^v-radio-283$&#34;,&#34;010&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r17,3,&#34;^v-radio-293$&#34;,&#34;010&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r18,3,&#34;^Recevoir la confirmation par SMS$&#34;,&#34;1&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r19,3,&#34;^Avertissez-moi lorsque de nouveaux services sont disponibles dans ma région$&#34;,&#34;1&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r20,3,&#34;^tosAndGDPRAgreement$&#34;,&#34;1&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,  
r21,0,&#34;^birthday$&#34;,&#34;1975-04-21&#34;,&#34;clients3.clicsante.ca/.*/take-appt&#34;,0,`

### Conclusion

Le code du bot n’est pas dispo, pas la peine de demander, car c’est un outil pédagogique.

Même si je suis heureux qu’il y ai un site de reservation au Quebec et qu’on ai pas à faire la file pendant des heures, je voudrais quand même dire au gouvernement qu’il pourrait faire mieux.

Ce genre de site procure beaucoup de frustrations, surtout pour les personnes qui ne sont pas habiles avec les ordinateurs ou ceux qui doivent utiliser un telephone cellulaire. Au final le risque c’est de décourager les gens de s’enregistrer, ou de saturer les lignes téléphoniques des pharmacies.

Pourtant, ca fait un an qu’on sait que les vaccins arrivent et qu’on a besoin d’un site comme celui ci. Et TicketMaster™ sait comment reserver temporairement ne place depuis peut-etre 30 ou 40 ans, avant internet. Alors pourquoi pas le gouvernement ?

Bon, vous me direz, de toute manière on a pas assez de vaccins pour tout le monde pour le moment, OK. Mais c’est le genre de site qui me donne envie de défoncer mon ordinateur a coup de pieds. Heureusement que je n’ai pas de hache à portée de main…

Perso, j’ai réussi à avoir mon vaccin, alors bonne chance !
