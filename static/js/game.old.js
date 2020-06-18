var reponses_courante="/";
var distanceHamming=1;
var url = '/api/v1.0/questionideale/'
var compteur=1;
function update() {
    $.ajax({
    type : 'GET',
    url : url + distanceHamming.toString() +reponses_courante,
    success: function (response) {
        console.log(response);
        if(response.nombre_oeuvres_restantes >1) {
            $('#question').text(response.question);
            $('#numero').text("Question n°"+compteur);
        }

        if(response.nombre_oeuvres_restantes === 1 || response.nombre_oeuvres_restantes===0 ) {

            console.log("trouve"+compteur);

            $('#trouver').text("Trouvé en"+compteur);
            $('body').html('<body> <img src="/static/image/UniversiteParis_logo_blanc.png" class="logo_fac">\n' +
                '    <a href="/" ><img class= "logo_home" src="/static/image/home.png"></a>\n<img id="image" src="{{url_for(\'static\', filename = \'image/cpepperidee.png\')}}" class="logo_fin"></img>\n' +
                '    <p class="penser">Tu penses à:</p> ' +
                '    <p id="question" class="ques_fin">{{ question }}</p> ' +
                '    <p id="trouver" class="trouve">Trouvé en</p>' +
                '    <img src="static/image/bulle.png" class="bulle_fin" >' +
                '    <img id="jacket" class="jacket"></img>  ' +
                '    <img src="/static/image/pellicule.png" class="pell"></img>' +
                '    <a class="buttonRejouer" href="jeu.html"><span class="material-icons">autorenew</span>Rejouer</a>' +
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

function boutonOui() {
    reponses_courante+="1";
    update();
    compteur++;
}

function boutonNon() {
    reponses_courante+="0";
    update();
    compteur++;
}
function boutonJsp() {
    reponses_courante+="2";
    update();
    compteur++;
}
function boutonProbOui() {
    reponses_courante+="3";
    update();
    compteur++;
}
function boutonProbNon() {
    reponses_courante+="4";
    update();
    compteur++;
}

function replaceAll(machaine, chaineARemaplacer, chaineDeRemplacement) {
   return machaine.replace(new RegExp(chaineARemaplacer, 'g'),chaineDeRemplacement);
 }
