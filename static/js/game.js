var reponses={};
var id_question_courante=1;
var distanceHamming=1;
var url = '/api/v2.0/questionideale/';
let url_update = '/api/v2.0/update_reponse/';
var url2 = '/api/v2.0/questions';
let id_deduction = -1;
var url3 = '/api/v2.0/reponses/';
var question;
var compteur=1;
var listequestion = {};
var listereponses = {};
let film_deja_propose = [];

function update() {
    $.ajax({
        type : 'GET',
        url : url + distanceHamming.toString(),
        data: reponses,
        success: function (response) {
            id_question_courante=response.id_question;
            console.log(response);
            if(response.nombre_oeuvres_restantes >1) {
                $('#question').text(response.question);
                $('#numero').text("Question n°"+compteur);
            }
            enableButton();

            if(response.nombre_oeuvres_restantes === 1 || response.nombre_oeuvres_restantes===0 ) {
            id_deduction = response.id_deduction;
            film_deja_propose.push(id_deduction);
            console.log("trouve"+compteur);

            $('#trouver').text("Trouvé en"+compteur);
            $('body').html('<div> <img src="/static/image/UniversiteParis_logo_blanc.png" class="logo_fac">\n' +
                '    <div class="div_logo_home"><a href="/" ><img class= "logo_home" src="/static/image/home.png"></a></div>\n' +
                '    <div><div>' +
                '    <div class="blockquote-wrapper">'+
                '    <div class="blockquote">'+
                '    <h1><span id="numero" class="blockquote_question"> S\'agit-il de : </span><span id="question"> {{ question }} </span><span id="trouver" class="trouve">Trouvé en</span></h1></div></div>' +
                '    <div class="pepper_jacket"><div id="pepper_fin"><img id="image" src="{{url_for(\'static\', filename = \'image/cpepperidee.png\')}}" class="logo_fin"></div>\n' +
                '    <div class="jacket_pell"><img id="jacket" class="jacket">' +
                '    <img src="/static/image/pellicule.png" class="pell"></div></div>' +
                '    <div id="oui_non"><button id="oui"  onclick="boutonVictoire()">Oui</button><button id="non" onclick="boutonPageContinuer()">Non</button></div>'+
                '\n  </body>')

            $('#question').text(response.deduction);
            $('#trouver').text("Trouvé en "+compteur+" questions");
            $('#image').attr('src','static/image/cpepperidee.png');

            var xhr = new XMLHttpRequest();
            xhr.open('GET','static/image/jaquette/' + response.id_deduction + '.png', false);
            xhr.send();

            if(xhr.status !="200"){
                var api= "http://omdbapi.com/?apikey=7ddf302f&t=";
                str1=response.deduction;
                nom_film_sans_espace=replaceAll(str1," ","+");
                poster_json=api.concat(nom_film_sans_espace);
                obj=$.getJSON(poster_json, function (json) {
                    poster_url=json.Poster;
                    $('#jacket').attr('src',poster_url);
                });
            }else {
                $('#jacket').attr('src','static/image/jaquette/' + response.id_deduction + '.png');
            }

        }
            else if (response.nombre_oeuvres_restantes <80 && response.nombre_oeuvres_restantes >60){
                $('#image').attr('src','static/image/cpeppercontentinterro.png');
            }
            else if (response.nombre_oeuvres_restantes < 60 && response.nombre_oeuvres_restantes >40 ){
                $('#image').attr('src','static/image/cpeppertristeinterro2.png');
            }
            else if (response.nombre_oeuvres_restantes < 40 && response.nombre_oeuvres_restantes >30 ){
                $('#image').attr('src','static/image/cpeppercontentinterro2.png');
            }
            else if (response.nombre_oeuvres_restantes < 30 && response.nombre_oeuvres_restantes >15 ){
                $('#image').attr('src','static/image/cpeppercontentinterro1.png');
            }
            else if (response.nombre_oeuvres_restantes < 15 && response.nombre_oeuvres_restantes >5 ){
                $('#image').attr('src','static/image/cpeppersourirecoin.png');
            }

            else if (response.nombre_oeuvres_restantes < 5 && response.nombre_oeuvres_restantes >2 ){
                $('#image').attr('src','static/image/cpepperideeo.png');
            }

        }
    })
}
function update_compteur() {

    $.ajax({
        method: 'POST',
        url : url_update+id_deduction,
        data: reponses,
        success:function (response) {
            console.log(response)
        },
    })
}
function boutonValiderFin(){
    $('body').load("/bilan.html", function () {
        let table = document.querySelector("table");
        let data = Object.keys(reponses);
    
        function generateTableHead(table, data) {
            let thead = table.createTHead();
            let row = thead.insertRow();
            for(let key of data) {
                let th = document.createElement("th");
                let text =  document.createTextNode(key);
                th.appendChild(text);
                row.appendChild(th);

            }
        }

        function generateTable(table, data) {
            for (let element of data) {
                let row = table.insertRow();
                for (key in element) {
                    let cell = row.insertCell();
                    let text = document.createTextNode(element[key]);
                    cell.appendChild(text);
                }
            }
        }

        //generateTableHead(table,data)
        generateTable(table,data);
    });
}
function boutonPageContinuer(){
    $('body').load('/page_continuer.html')
}
function boutonHamming() {
    distanceHamming+=1;
    $('body').load("/body_jeu.html");
    update();
}

function obtenir_reponses(isSuggestion=false){
   $.ajax({
    type : 'GET',
    url : url3 + id_deduction,
    data : reponses,
    success : function(resultat){
        listereponses= resultat;
          boutonBilan(isSuggestion);

        }
    })
}

function boutonBilan(isSuggestion=false){
     $('body').load("/bilan.html", function () {
        let table = document.querySelector("table");
        let data = Object.keys(reponses);
        //Désactive (cache) le bouton de correction si l'oeuvre recherchée à été
         // trouvée dans la liste de suggestion
        if (isSuggestion) {
            document.getElementById("corrigerBilan").style.display = 'none';
            document.getElementById("th_corriger").style.display = 'none';
            document.getElementById("question").textContent = "Voici les questions auxquelles vous avez répondu au cours de cette partie.";
            document.getElementsByClassName("div_tab")[0].setWidth = '63vw';
        }
        function bis(data){
                for(const key in data){
                    if(data[key] == 1){
                        data[key] = "Oui";
                    }
                    else if(data[key] == 0){
                        data[key] = "Non";
                    }
                    else if(data[key] == 2){
                        data[key] = "Ne sais pas";
                    }
                    else if(data[key] == 3){
                        data[key] = "Probablement";
                    }
                    else if(data[key] == 4){
                        data[key] = "Probablement pas";
                    }
                }
            return data;
        }

        var data_bis = bis(reponses);
        var donnee = Object.entries(data_bis);

        function generateTable(table, data) {
            let tbody = table.createTBody();
            for (let element of data) {
                let row = table.insertRow();
                let cell = row.insertCell();
                let text = document.createTextNode(listequestion[element[0]]);
                   // console.log(key);
                   // console.log(listequestion[key]);
                cell.appendChild(text);
                let cell1 = row.insertCell();
                if(listereponses[element[0]] === true){
                    let text1 = document.createTextNode("Oui");
                    cell1.appendChild(text1);
                }
                else if(listereponses[element[0]] === false){
                    let text1 = document.createTextNode("Non");
                    cell1.appendChild(text1);
                }
                let cell2 = row.insertCell();
                let text2 = document.createTextNode(element[1]);
                cell2.appendChild(text2);
                //S'il s'agit d'un résumé de partie après avoir trouvé l'oeuvre, ajoute
                //la colonne concernant les modifications à faire si l'utilisateur le souhaite
                if(!isSuggestion){
                    let cell3 = row.insertCell();
                    if(cell1.textContent != cell2.textContent){
                        let box = document.createElement("INPUT");
                        box.setAttribute("type", "checkbox");
                        box.setAttribute("id", element[0]);
                        cell3.appendChild(box);
                    }
                    else{
                        let text3 = document.createTextNode("");
                        cell3.appendChild(text3);
                    }
                }
                tbody.appendChild(row);
                }
            }


        //generateTableHead(table,data);
        generateTable(table,donnee);
        console.log(donnee);
    });

}
function boutonVictoire() {
    $('body').load("/page_victoire.html")
}

function confirmerSuggestion(id) {
    id_deduction = id;
    $('body').load("/confirmation.html")
}
function boutonSuggestion() {

    $.ajax({
        type : 'GET',
        url:'/api/v2.0/film_ressemblant/',
        data:reponses,
        success: function (response) {
            console.log(response);
            $('body').load("/suggestion.html", function () {
            var compteur=-1;
                    for (let element in response.liste_titre){
                        if (!(film_deja_propose.includes(response.liste_id[compteur+1]))){


                            var iden = document.getElementById("liste");
                            var eListe = document.createElement("li");
                            var eImage = document.createElement("img");
                            var eTitre = document.createElement("span");

                            eListe.appendChild(eImage);
                            eListe.appendChild(eTitre);
                            compteur++;
                            let id = response.liste_id[compteur];
                            eTitre.append(response.liste_titre[compteur]);
                            $(eImage).attr('src', 'static/image/jaquette/' + response.liste_id[compteur] + '.png');
                            eImage.addEventListener("click",function(){correction(id);confirmerSuggestion(id)});
                            iden.appendChild(eListe);  // on attache le noeud item de liste au noeud liste

                        }
                        else{
                            compteur++;
                        }

                    }
            })

        }
    })

}
function disableButton() {
    $("#Oui").attr('disabled',true);
    $('#Non').attr('disabled',true);
    $('#Jsp').attr('disabled',true);
    $('#ProbOui').attr('disabled',true);
    $('#ProbNon').attr('disabled',true);
}
function enableButton() {
    $('#Oui').prop('disabled',false);
    $('#Non').prop('disabled',false);
    $('#Jsp').prop('disabled',false);
    $('#ProbOui').prop('disabled',false);
    $('#ProbNon').prop('disabled',false);
}
function boutonOui() {
    reponses[id_question_courante]=1;
    disableButton();
    update();
    compteur++;
}
function obtenir_question(){
    update_compteur();
    $.ajax({
    type : 'GET',
    url : url2,
    data : reponses,
    success : function(result){
        listequestion = result;

        boutonBilan();
        }
    })
}
function boutonNon() {
    reponses[id_question_courante]=0;
    disableButton();
    update();
    compteur++;
}
function boutonJsp() {
    reponses[id_question_courante]=2;
    disableButton();
    update();
    compteur++;
}
function boutonProbOui() {
    reponses[id_question_courante]=3;
    disableButton();
    update();
    compteur++;
}
function boutonProbNon() {
    reponses[id_question_courante]=4;
    disableButton();
    update();
    compteur++;
}


function replaceAll(machaine, chaineARemaplacer, chaineDeRemplacement) {
    return machaine.replace(new RegExp(chaineARemaplacer, 'g'),chaineDeRemplacement);
}

var liste_correction = {};

function getlistecorrection(){
    var checkbox = document.getElementsByTagName("INPUT");
        console.log(checkbox);
        for(var i = 0; i < checkbox.length; i++){
            if(checkbox[i].checked == true){
                liste_correction[checkbox[i].id] = !listereponses[checkbox[i].id];
            }
        }
}

function correction(id_oeuvre=null){
    console.log(id_oeuvre);
    let trouve = true;
    let liste_correc = liste_correction;
    if (id_oeuvre){
        trouve = false;
        id_deduction = parseInt(id_oeuvre);
        liste_correc = reponses
    }
    //reponses user en 0 et 1 -> bool(reponses)
    let url_correction = '/api/v2.0/correct_errors/' + id_deduction + "/" + trouve;
    $.ajax({
    type: 'POST',
    url: url_correction,
    data: liste_correc,
    success: function(corriger){
    }
    })
}

/**
 * Vérifie si l'oeuvre que l'utilisateur souhaite ajouter dispose d'un titre, d'une année,
 * d'une question et d'une réponse (à cette question) valide.
 * @returns {boolean}
 */
function verifier_ajout_oeuvre(){
    retour = true
    //Récupère les différents éléments du formulaire afin de faire des vérifications
    //quant à l'intégrité de informations fournies
    let oeuvre = document.forms["form_ajout_oeuvre"]["ajout_oeuvre"];
    let question = document.forms["form_ajout_oeuvre"]["ajout_question"];
    let annee = document.forms["form_ajout_oeuvre"]["ajout_annee"];
    let reponse = document.forms["form_ajout_oeuvre"]["ajout_reponse"];
    let submit = document.getElementById("buttonSubmit");
    //Récupère l'année actuelle pour comparaison avec l'année entrée par
    //l'utilisateur
    annee_actuelle = new Date().getFullYear()
    if(oeuvre.value === "" || question.value === "" || annee.value === ""
        || reponse.value === "" ) {
        submit.disabled = false
        retour = false
        alert("Ajouter une oeuvre ainsi qu'une question pour la distinguer des autres suggestions")
    }
    //Empêche la validation si la réponse ne correspond pas à oui ou non
    else if(!(reponse.value === "Oui" || reponse.value === "oui" ||
        reponse.value === "Non" || reponse.value || "non")){
            reponse.setCustomValidity("Entrez 'Oui' ou 'Non' comme réponse")
            retour = false
    }
    //Empêche la validation si l'année est inférieure à celle de la première oeuvre cinématographique
    else if(annee.value < 1895){
        annee.setCustomValidity("Entrer une année valide, soit supérieure à 1895")
        retour = false
    }
    //Empêche la validation si l'année est supérieure à celle actuelle
    else if(annee.value > annee_actuelle){
        annee.setCustomValidity("Nous sommes en 2020, veuillez entrez une année valide")
        retour = false
    }
    //Réactive le bouton valider
    else{
        submit.disabled = true
    }
    return retour;
}

/**
 * Envoie une oeuvre, ainsi que les réponses de l'utilisateur
 * pendant la partie à l'API afin de l'ajouter à la liste des propositions.
 * Lorsqu'il s'agit d'une nouvelle oeuvre, une nouvelle question est ajoutée à la base de données
 * @param {boolean} nouveau
 */
function soumettre_oeuvre(nouveau) {
    // Vérifie avant de soumettre que l'oeuvre est valide
    if (verifier_ajout_oeuvre()) {
        // Récupère les valeurs de l'oeuvre, son année de parution, et des réponses
        let titre = document.forms["form_ajout_oeuvre"]["ajout_oeuvre"].value;
        let question = document.forms["form_ajout_oeuvre"]["ajout_question"].value;
        let annee = document.forms["form_ajout_oeuvre"]["ajout_annee"].value;
        let choix = document.forms["form_ajout_oeuvre"]["ajout_reponse"].value;
        // Choix passe à true si la réponse est oui, false si c'est non.
        choix = choix === 'Oui' || choix === 'oui';
        //Créer la struture de données à envoyer à l'API
        let data = {
            titre: titre,
            annee: annee,
            question: question,
            choix: choix,
            reponses: reponses,
        }
        //Lance une requête ajax à l'API
        $.ajax({
                type: 'POST',
                url: '/api/v2.0/suggest_oeuvre',
                data: data,
                success: function (reponse) {
                    $('body').load("/jeu.html");
                    console.log("reponse: " + reponse);
                }
            }
        )
    }
}

function buttonAccueil(){
    $('html').load("/jeu.html");
}