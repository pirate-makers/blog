---
title: "Comment se faire vacciner au Quebec"
author: "Prune"
date: 2021-04-29T21:05:54.543Z
lastmod: 2023-11-30T22:23:39-05:00

description: ""

subtitle: "Il y a deux semaines le Quebec a ouvert la vaccination aux personnes de 45 ans et plus, avec le vaccin AstraZeneca."

image: "images/1.png" 
images:
 - "images/1.png"
 - "images/2.png"
 - "images/3.png"
 - "images/4.png"
 - "images/5.png"
 - "images/6.png"

tags: ["hacking", "life"]

aliases:
    - "/comment-se-faire-vacciner-au-quebec-c3f7c09aaf6d"

---

![image](images/1.png#layoutTextWidth)
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
![image](images/2.png#layoutTextWidth)


*   sélectionner la date souhaité (en general, on a pas le choix), puis l’heure
![image](images/3.png#layoutTextWidth)


*   remplir un lonnnng formulaire, ce qui prend en general au moins 30s si vous tapez vite, voir plus
![image](images/4.png#layoutTextWidth)


Note: votre No d’assurance maladie, c’est **PAS VOTRE N.A.S**, mais le code en bas de votre carte soleil, qui commence par les 3 lettres de votre nom et la 1ere lettre de votre prénom, puis votre age (ex: FOOJ 740712..)

En general quand vous en êtes la, vous cliquez sur “SOUMETTRE” en bas de page et ca vous dit que votre choix n’est plus disponible.

![image](images/5.png#layoutTextWidth)


### 2eme tentative

Vous recommencez le process du debut, et encore une fois, le temps de remplir le formulaire, votre place n’est plus dispo…

![image](images/6.png#layoutTextWidth)


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
```bash
echo cHVibGljQHRyaW1vei5jb206MTIzNDU2Nzgh |base64 -D

[public@trimoz.com](mailto:public@trimoz.com):12345678!
```

Surprise: le Token est le meme pour tout le monde, et semble contenir le nom du “produit” (le site web):

[http://trimoz.com](http://trimoz.com) -> [https://clichealth.net/](https://clichealth.net/) -> [https://emsolutions.ca/](https://emsolutions.ca/)

Bref, meme si ce n’est pas grave et que ce site ne contient (pour le moment) aucune donnée sensible, je dis un grand bravo au(x) champion(s) qui ont fait ca.   
En tout cas moi j’ai ri.   
C’est sympa pour nous, car du coup on peut le mettre “en dur” dans notre bot.

Donc, une fois qu’on a le code-postal et le Token, on peut commencer à taper dans l’API du site.

#### Geocoding

Le site vous présente la liste des lieux de vaccination les plus proches. Il utilise donc votre code postal pour définir le centre de la zone de recherche. Pour faire simple, il utilise vos coordonnées GPS et une bounding-box.

Le 1er appel est donc l’API de geocoding:
```json
GET https://api3.clicsante.ca/v3/geocode?address=h1a0a1
{  
  "results": [  
    {  
      "address_components": [  
        {  
          "long_name": "H1A 0A1",  
          "short_name": "H1A 0A1",  
          "types": [  
            "postal_code"  
          ]  
        },  
        {  
          "long_name": "Riviere-des-Prairies—Pointe-aux-Trembles",  
          "short_name": "Riviere-des-Prairies—Pointe-aux-Trembles",  
          "types": [  
            "political",  
            "sublocality",  
            "sublocality_level_1"  
          ]  
        },  
        {  
          "long_name": "Montreal",  
          "short_name": "Montreal",  
          "types": [  
            "locality",  
            "political"  
          ]  
        },  
        {  
          "long_name": "Montreal",  
          "short_name": "Montreal",  
          "types": [  
            "administrative_area_level_2",  
            "political"  
          ]  
        },  
        {  
          "long_name": "Quebec",  
          "short_name": "QC",  
          "types": [  
            "administrative_area_level_1",  
            "political"  
          ]  
        },  
        {  
          "long_name": "Canada",  
          "short_name": "CA",  
          "types": [  
            "country",  
            "political"  
          ]  
        }  
      ],  
      "formatted_address": "Montreal, QC H1A 0A1, Canada",  
      "**geometry**": {  
        "bounds": {  
          "northeast": {  
            "lat": 45.652886,  
            "lng": -73.5001424  
          },  
          "southwest": {  
            "lat": 45.6519153,  
            "lng": -73.50257289999999  
          }  
        },  
        "**location**": {  
          "lat": 45.6524306,  
          "lng": -73.5012086  
        },  
        "location_type": "APPROXIMATE",  
        "viewport": {  
          "northeast": {  
            "lat": 45.65374963029149,  
            "lng": -73.50000866970849  
          },  
          "southwest": {  
            "lat": 45.65105166970849,  
            "lng": -73.5027066302915  
          }  
        }  
      },  
      "place_id": "ChIJA91J-y_iyEwRvgm6PIfurds",  
      "types": [  
        "postal_code"  
      ]  
    }  
  ],  
  "status": "OK"  
}
```

Nous avons besoin de **results[0].geometry.location** pour faire notre recherche.

#### La recherche

La, ça se complique. On va décortiquer l’URL:
```
GET https://api3.clicsante.ca/v3/availabilities?dateStart=2021-04-29&dateStop=2021-08-27&latitude=45.6524306&longitude=-73.5012086&maxDistance=1000&serviceUnified=237&postalCode=H1A%200A1&page=0
```

*   [https://api3.clicsante.ca/v3/availabilities](https://api3.clicsante.ca/v3/availabilities?)  
ca c’est le endpoint
*   **dateStart**=2021–04–29  
OK, ca c’est aujourd’hui
*   **dateStop**=2021–08-27  
Ca c’est… dans 1 mois
*   **latitude**=45.6524306&**longitude**=-73.5012086  
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
```json
 {
  "establishments": [  
    {  
      "id": 60093,  
      "name": "CIUSSS de lEst-de-lÎle-de-Montréal  - Centre Machin- Citoyens - Vaccin COVID-19",  
      "phone": "",  
      "address": "125 Rue Notre-Dame Est, Pointe-aux-Trembles, QC H2B 2Y2",  
      "public_url": "[https://clients3.clicsante.ca/60093](https://clients3.clicsante.ca/60093)"  
    },  
    {  
      "id": 61047,  
      "name": "Accès Pharma/Wal-Mart - Jean  Le Tong Le pharmaciennes SENC - Vaccin COVID-19 Citoyen",  
      "phone": "(514) 555-6505",  
      "address": "126, SHERBROOKE, POINTE-AUX-TREMBLES, H2A 2V9",  
      "public_url": "[https://clients3.clicsante.ca/61047](https://clients3.clicsante.ca/61047)"  
    },  
  ],  
  "places": [  
    {  
      "id": 6062,  
      "establishment": 73215,  
      "name_fr": "Jean Messier - AstraZeneca",  
      "name_en": "Jean Messier - AstraZeneca",  
      "formatted_address": "100, BOUL. SAINT-JEAN-BAPTISTE, POINTE-AUX-TREMBLES, H2B 2A5",  
      "latitude": 45.2414221,  
      "longitude": -73.2026806,  
      "is_virtual": 0,  
      "availabilities": {  
        "su237": {  
          "t07": 255,  
          "ta7": 0  
        }  
      }  
    },  
    {  
      "id": 2017,  
      "establishment": 60093,  
      "name_fr": "Centre Rouseay",  
      "name_en": "Centre Rouseay",  
      "formatted_address": "121 Rue Notre-Dame Est Montréal H2B2Y4 Canada",  
      "latitude": 45.6409872,  
      "longitude": -73.4902212,  
      "is_virtual": 0,  
      "availabilities": {  
        "su237": {  
          "t07": 2520,  
          "ta7": 54745  
        }  
      }  
    },  
  ],  
  "distanceByPlaces": {  
    "3357": 1,  
    "3168": 1,  
    "6062": 1,  
    "3390": 2,  
    "3381": 2,  
    "6688": 2,  
    "6182": 2,  
    "3427": 2,  
    "3174": 2,  
    "6301": 2,  
    "2017": 2,  
    "4373": 6,  
    "3812": 6,  
    "3770": 6,  
    "4349": 6  
  },  
  "serviceIdsByPlaces": []  
}
```

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

```go
// on commence a la page 0  
nextPage := 0

// on entre dans la boucle  
for {
  // on cree l'URL pour la page courante  
  req, err := newGetRequest(fmt.Sprintf("%s&page=%d", url, nextPage))  
  if err != nil {  
    return err  
  }
  // on execute la requete HTTP  
  resp, err := http.DefaultClient.Do(req)  
  if err != nil {  
    return err  
  }
  // so on recoit un code 204, on arrete  
  if resp.StatusCode != 200 {  
    fmt.Printf("done\n, ")  
    resp.Body.Close()  
    break  
  }  
...
```

#### Filtrage

Une requête sur Montreal peut facilement donner 8 a 16 pages, car ce sont tous les lieux a proximité sans regarder si il y a de la place ou pas.

Heureusement pour nous, enfin, pour mon ami **Emmanuel** et moi, qui sommes des 45+ et qui ne peuvent recevoir QUE le AstraZeneca, tous les lieux compatibles sont suffixés avec `— AstraZeneca` . On peut donc facilement éliminer les lieux indésirables de la liste.

Il y a aussi un champs “availabilities” dans les **Places**, qui semble indiquer la dispo mais pas si c’est du AstraZeneca… donc on ne l’utilise pas pour le moment.

#### Service

Chaque `etablissement` a son propre numero de `service` . On doit donc faire une nouvelle requête pour chaque:

```json
GET https://api3.clicsante.ca/v3/establishments/73215/services

[  
  {  
    "id": 6563,  
    "establishment": 73215,  
    "service_template": {  
      "id": 159,  
      "name": "1st_dose_COVID_19_vaccine_astrazeneca",  
      "descriptionFr": "1ère dose - Vaccin contre la COVID-19 - AstraZeneca",  
      "descriptionEn": "1st dose - COVID-19 vaccine AstraZeneca"  
    },  
    "module": 20,  
    "name_fr": "AstraZeneca - 1ère dose - Vaccin contre la COVID-19",  
    "name_en": "AstraZeneca - 1st dose - COVID-19 vaccine",  
    "description_fr": "<p>Vaccin contre la COVID-19 - AstraZeneca.</p>",  
    "description_en": "<p>COVID-19 Vaccine - AstraZeneca.</p>",  
    "enable_personal_description": true,  
    "length": 5,  
    "interval": 5,  
    "document_fr": "",  
    "document_en": "",  
    "price": 0,  
    "price_description_fr": "",  
    "price_description_en": "",  
...
```

La seule chose qui nous concerne c’est le `id: 6563`du debut. Le reste semble être la config et le message d’alerte a afficher lorsque la page s’ouvre.

#### Dispo

Maintenant qu’on a une liste épurée, on peut valider si le site a de la place, et quand:
```json
GET https://api3.clicsante.ca/v3/establishments/73215/schedules/public?dateStart=2021-04-27&dateStop=2021-05-30&service=6563&timezone=America/Toronto&places=60626&filter1=1&filter2=0

{  
  "availabilities": [  
    "2021-05-04",  
    "2021-05-05"  
  ],  
  "daysComplete": [],  
  "upcomingAvailabilities": [],  
  "pastAvailabilities": []  
}
```

On a donc de la place le 4 et le 5 mai.

On peut donc afficher les URLs pour rapidement joindre le site de reservation sans se taper toute la recherche.

L’URL ressemble a:
```
https://clients3.clicsante.ca/<etablissement_id>/take-appt?unifiedService=237&portalPlace=<place_id>&portalPostalCode=G6J%201Y7&lang=fr
```

Voila un exemple de ce que retourne le bot d’**Emmanuel**:

```bash
go run covid.go  -postal-code H1A0A1 -distance 10

gathering page 0, 1, 2, 3, done  
Parsed 36 places in total
Name: Jean Messier - AstraZeneca  
  Address: 5500, BOUL. SAINT-JEAN-BAPTISTE, POINTE-AUX-TREMBLES, H2B 2A2  
  Distance: 1Km  
  Available: [2021-05-04 2021-05-05]  
  Upcoming: []  
  Rendez-vous: [https://clients3.clicsante.ca/73215/take-appt?unifiedService=237&portalPlace=6062&portalPostalCode=G6J%201Y7&lang=fr](https://clients3.clicsante.ca/73215/take-appt?unifiedService=237&portalPlace=6062&portalPostalCode=G6J%201Y7&lang=fr)
  
Name: Centre Machin- AstraZeneca  
  Address: 12 Rue Notre-Dame Est Montréal H2B2Y2 Canada  
  Distance: 2Km  
  Available: [2021-04-29 2021-04-30]  
  Upcoming: []  
  Rendez-vous: [https://clients3.clicsante.ca/70021/take-appt?unifiedService=237&portalPlace=6301&portalPostalCode=G6J%201Y7&lang=fr](https://clients3.clicsante.ca/70021/take-appt?unifiedService=237&portalPlace=6301&portalPostalCode=G6J%201Y7&lang=fr)`

#### Loop

En lançant le bot dans une boucle, on peut verifier la dispo presque en temps reel:

```bash
while true ; do date ; go run covid.go  -postal-code H1A0A1 -distance 10 ; sleep 10 ; done
```

Mais dépêchez-vous… tant que la même place re-apparait toutes les 10 secondes, c’est que la place est encore dispo, mais des quelle part, c’est perdu, meme si vous avez presque fini de remplir la page.

### Autofill

J’ai bien essayé de faire un bout de javascript pour remplir les champs du formulaire, mais bon, tous ces trucs en react avec un DOM dynamique… Pi j’ai une vie, et un metier aussi…  
On ne peut pas non plus tout automatiser car if y a un re-captcha à la fin de la page, justement pour nous empêcher d’utiliser un bot. C’est con, on aurait pu reserver tous les slots et les revendre sur eBay, comme le font les scalpers avec les concerts 😐  
Restons serieux.   
Donc, votre navigateur a lui meme une fonction qui permet de pre-remplir les champs de formulaires. Malheureusement dans ce cas, il ne fonctionne pas car les champs ont un nom dynamique.

L’extension [autofill](https://addons.mozilla.org/en-CA/firefox/addon/autofill-quantum/) pour Firefox et un peu plus configurable. Elle permet de définir précisément comment reconnaitre chaque champs du formulaire.  
Ici, on utilise `clients3.clicsante.ca/.*/take-appt` ce qui a pour effet de matcher les champs meme si la clé dynamique change.

Voila la config que j’ai utilisé. Attention de bien respecter une majuscule pour les noms et les autres formatages spéciaux:
```
### AUTOFILL RULES ###,,,,,,  
Rule ID,Type,Name,Value,Site,Mode,Profile  
r1,0,"^first_name$","Change_me","clients3.clicsante.ca/.*/take-appt",0,  
r2,0,"^last_name$","Change_me","clients3.clicsante.ca/.*/take-appt",0,  
r3,0,"^email$","[change_me@ici.net](mailto:change_me@ici.net)","clients3.clicsante.ca/.*/take-appt",0,  
r4,0,"^Confirmation du courriel$","[change_me@ici.net](mailto:change_me@ici.net)","clients3.clicsante.ca/.*/take-appt",0,  
r5,0,"^phone$","(123) 456 - 1234","clients3.clicsante.ca/.*/take-appt",0,  
r6,0,"^cellphone$","(123) 456 - 1234","clients3.clicsante.ca/.*/take-appt",0,  
r7,0,"^nam$","ABCD 7504 2110","clients3.clicsante.ca/.*/take-appt",0,  
r8,0,"^mother_first_name$","Change_me","clients3.clicsante.ca/.*/take-appt",0,  
r9,0,"^mother_last_name$","Change_me","clients3.clicsante.ca/.*/take-appt",0,  
r10,0,"^father_first_name$","Change_me","clients3.clicsante.ca/.*/take-appt",0,  
r11,0,"^father_last_name$","Change_me","clients3.clicsante.ca/.*/take-appt",0,  
r12,3,"^v-radio-243$","010","clients3.clicsante.ca/.*/take-appt",0,  
r13,3,"^v-radio-253$","010","clients3.clicsante.ca/.*/take-appt",0,  
r14,3,"^v-radio-263$","010","clients3.clicsante.ca/.*/take-appt",0,  
r15,3,"^v-radio-273$","010","clients3.clicsante.ca/.*/take-appt",0,  
r16,3,"^v-radio-283$","010","clients3.clicsante.ca/.*/take-appt",0,  
r17,3,"^v-radio-293$","010","clients3.clicsante.ca/.*/take-appt",0,  
r18,3,"^Recevoir la confirmation par SMS$","1","clients3.clicsante.ca/.*/take-appt",0,  
r19,3,"^Avertissez-moi lorsque de nouveaux services sont disponibles dans ma région$","1","clients3.clicsante.ca/.*/take-appt",0,  
r20,3,"^tosAndGDPRAgreement$","1","clients3.clicsante.ca/.*/take-appt",0,  
r21,0,"^birthday$","1975-04-21","clients3.clicsante.ca/.*/take-appt",0,
```

### Conclusion

Le code du bot n’est pas dispo, pas la peine de demander, car c’est un outil pédagogique.

Même si je suis heureux qu’il y ai un site de reservation au Quebec et qu’on ai pas à faire la file pendant des heures, je voudrais quand même dire au gouvernement qu’il pourrait faire mieux.

Ce genre de site procure beaucoup de frustrations, surtout pour les personnes qui ne sont pas habiles avec les ordinateurs ou ceux qui doivent utiliser un telephone cellulaire. Au final le risque c’est de décourager les gens de s’enregistrer, ou de saturer les lignes téléphoniques des pharmacies.

Pourtant, ca fait un an qu’on sait que les vaccins arrivent et qu’on a besoin d’un site comme celui ci. Et TicketMaster™ sait comment reserver temporairement ne place depuis peut-etre 30 ou 40 ans, avant internet. Alors pourquoi pas le gouvernement ?

Bon, vous me direz, de toute manière on a pas assez de vaccins pour tout le monde pour le moment, OK. Mais c’est le genre de site qui me donne envie de défoncer mon ordinateur a coup de pieds. Heureusement que je n’ai pas de hache à portée de main…

Perso, j’ai réussi à avoir mon vaccin, alors bonne chance !
