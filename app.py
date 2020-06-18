from flask import Flask, render_template, jsonify, make_response, abort, request
from flask_admin import Admin
import re
from config_bdd import database_uri
from tables_bdd import db, Oeuvre, Question, Reponse, OeuvreView, QuestionView, ReponseView, PropositionOeuvreView, \
    PropositionQuestionView, PropositionReponseView, PropositionOeuvre, PropositionQuestion, PropositionReponse, \
    TraitementReponse, TraitementReponseView
from analysequestion import *
from datamanager import maj_compteurs_reponse, recuperer_questions, traiter_correction_proposee, traiter_oeuvre_proposee,\
    recuperer_reponse
import secrets

"""
Fichier du serveur Flask, à n'utiliser que dans un environnement de test.
Pour tout déploiement utiliser un uwsgi.py.

Examples:
        $ python app.py

Attributes:
        app (Flask): variable du module servant à associer app à une application serveur.
        
Todo:
    *Sécuriser l'API
    *Proposer une landing page
    *Proposer une page d'ajout de film ou série non répertorier

"""
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = database_uri
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = "False"
app.config['SECRET_KEY'] = secrets.token_urlsafe(16)
# set optional bootswatch theme
app.config['FLASK_ADMIN_SWATCH'] = 'flatly'
admin = Admin(app, name='Peppinator', template_mode='bootstrap3')

admin.add_view(PropositionOeuvreView(PropositionOeuvre, db.session, category='Proposition'))
admin.add_view(PropositionQuestionView(PropositionQuestion, db.session, category='Proposition'))
admin.add_view(PropositionReponseView(PropositionReponse, db.session, category='Proposition'))

admin.add_view(OeuvreView(Oeuvre, db.session, category="Données"))
admin.add_view(QuestionView(Question, db.session, category="Données"))
admin.add_view(ReponseView(Reponse, db.session, category="Données"))

admin.add_view(TraitementReponseView(TraitementReponse, db.session))
# Add administrative views here


db.init_app(app)


# TODO see sqlalchemy_track_modifications


# TODO see sqlalchemy_track_modifications


@app.route('/')
@app.route('/accueil.html')
def accueil():
    """
    Page html à la racine de l'addresse du serveur.
    :return:fichier html avec l'argument question qui correspond à la première question affichée
    """
    return render_template('accueil.html')


@app.route('/body_jeu.html')
def body_jeu():
    return render_template('body_jeu.html')


@app.route('/bilan.html')
def bilan():
    return render_template('bilan.html')


@app.route('/api/v2.0/questions')
def get_questions():
    liste_questions_non_formatees = recuperer_questions()
    dictionnaire_questions_formatees = {}
    for question in liste_questions_non_formatees:
        dictionnaire_questions_formatees[question.id] = question.texte
    return jsonify(dictionnaire_questions_formatees)


@app.route('/jeu.html')
@app.route('/jeu')
def jeu():
    return render_template('jeu.html', question="Est-ce une série ?")


@app.route('/page_continuer.html')
def page_continuer():
    return render_template('page_continuer.html')


@app.route('/page_victoire.html')
def page_victoire():
    return render_template('page_victoire.html')


@app.route('/suggestion.html')
def suggestion():
    return render_template('suggestion.html')


@app.route('/confirmation.html')
def confirmation():
    return render_template('confirmation.html')

@app.route('/api/v1.0/questionideale/<distance_hamming>/<sumreponse>')
def get_question_ideale(sumreponse, distance_hamming=1):
    """
    fonction de l'API REST à l'adresse <hostname>/api/v1.0/questionideale/<distance_hamming>/<sumreponse>
    Elle sert à renvoyer la question idéale pour une suite de réponses donné

    :param distance_hamming: Distance de hamming à laquelle on trie la liste
    :param sumreponse: (String) Ce paramètre correspond à la suite de réponses de l'utilisateur
                                    exemple si l'utilisateur répond oui puis non puis je ne
                                    sais pas puis non, on aura sumreponse = "1020"
                                Pour référence: 0 correspond à non
                                                1 correspond à oui
                                                2 correspond à je ne sais pas
                                                3 correspond à probablement
                                                4 correspond à probablement pas
    :return: Un JSON correspondant à la variable réponse
                Example:
                    une requête GET à <hostname>/api/v1.0/questionideale/1100111 donne:
                        {
                            deduction: "AUCUNE",
                            nombre_oeuvres_restantes: 46,
                            question: "Est-ce un oeuvre comique ?"
                        }
    Todo:
        *gestion des exceptions
        *test unitaires
    """

    if re.search("[^0-4]", sumreponse) is not None:
        abort(400)
    distance_hamming = int(distance_hamming)
    liste_reponses = list()
    """
        Boucle for transformant un String en liste d'entier
        -> "01234" en [0,1,2,3,4]
    """
    for charactere in sumreponse:
        liste_reponses.append(int(charactere))
    liste_filtre, liste_questions_posees = filter_liste(liste_reponses, distance_hamming)
    """
        deduction correspond au titre de l'unique film de la liste filtree s'il y a encore
        plusieurs films ou aucun film dans la liste celui-ci prend la valeur par défault
        "AUCUNE".
    """
    deduction = "AUCUNE"
    id_deduit = -1
    if len(liste_filtre) == 1:
        deduction = liste_filtre[0].titre
        id_deduit = liste_filtre[0].id_film
    """
        reponse est le dictionnaire qu'on renvoie sous forme de JSON
    """
    reponse = {
        "id_deduction": id_deduit,
        "question": question_ideale(liste_filtre, liste_questions_posees)[1],
        "nombre_oeuvres_restantes": len(liste_filtre),
        "deduction": deduction
    }
    return jsonify(reponse)


@app.route('/api/v2.0/update_reponse/<id_film>', methods=['POST'])
def update_reponse(id_film):
    """
    Fonction de l'API REST à l'adresse <hostname>/api/v2.0/maj_compteurs_reponse/<reponse>
    """
    #
    success = True
    for id_question, reponse in request.form.items():
        # Met à jour une par une les réponses et donc leurs compteurs en fonction du choix utilisateur
        if not maj_compteurs_reponse(id_oeuvre=id_film, id_question=id_question, choix=int(reponse)):
            success = False
    print("succès : {}".format(success))
    reponse = {
        "success_update_reponse": success
    }

    return jsonify(reponse)


@app.route('/api/v2.0/correct_errors/<id_oeuvre>/<trouve>', methods=['POST'])
def corriger_erreurs(id_oeuvre, trouve):
    success = True
    trouve = trouve == "true"
    print(trouve)
    if trouve is False:
        print("inside")
        reponses = dict()
        for id_question, reponse in request.form.items():
            print(id_question + " " + reponse)
            reponses[int(id_question)] = int(reponse)
        reponses_attendues = reponse_attendu(reponses.keys(), id_oeuvre)
        for (id_question, reponse), (id_question_2, reponse_attendue) in zip(reponses.items(), reponses_attendues.items()):
            if not (reponse == reponse_attendue):
                print("id_q : {} rep : {}".format(id_question, reponse))
                if not traiter_correction_proposee(id_oeuvre, id_question, bool(reponse)):
                    success = False
    else:
        # Ajoute une par une les erreurs dans les tables de propositions
        for id_question, reponse in request.form.items():
            if not traiter_correction_proposee(id_oeuvre, id_question, bool(reponse)):
                success = False
    print("succès : {}".format(success))
    return jsonify(success)


@app.route('/api/v2.0/suggest_oeuvre', methods=['POST'])
def suggest_oeuvre():
    success = True
    titre = request.form['titre']
    annee = request.form['annee']
    texte = request.form['question']
    choix = bool(request.form['choix'])
    list_no_reponses = ['titre', 'annee', 'question', 'choix', 'nouveau']
    reponses_correctes = dict()
    for id_question, reponse in request.form.items():
        if id_question not in list_no_reponses:
            id_correct = int(re.sub("[^0-9]", "", id_question))
            print("{} {}".format(id_correct, reponse))
            reponses_correctes[id_correct] = bool(int(reponse))
    traiter_oeuvre_proposee(titre, annee, reponses_correctes, texte, choix)
    return jsonify(success)


@app.route('/api/v2.0/questionideale/<distance_hamming>')
def get_question_ideale_v2(distance_hamming=1):
    """
    fonction de l'API REST à l'adresse <hostname>/api/v1.0/questionideale/<distance_hamming>/<sumreponse>
    Elle sert à renvoyer la question idéale pour une suite de réponses donné

    :param distance_hamming: Distance de hamming à laquelle on trie la liste
    :param sumreponse: (String) Ce paramètre correspond à la suite de réponses de l'utilisateur
                                    exemple si l'utilisateur répond oui puis non puis je ne
                                    sais pas puis non, on aura sumreponse = "1020"
                                Pour référence: 0 correspond à non
                                                1 correspond à oui
                                                2 correspond à je ne sais pas
                                                3 correspond à probablement
                                                4 correspond à probablement pas
    :return: Un JSON correspondant à la variable réponse
                Example:
                    une requête GET à <hostname>/api/v1.0/questionideale/1100111 donne:
                        {
                            deduction: "AUCUNE",
                            nombre_oeuvres_restantes: 46,
                            question: "Est-ce un oeuvre comique ?"
                        }
    Todo:
        *gestion des exceptions
        *test unitaires
    """

    """
        Boucle for transformant un String en liste d'entier
        -> "01234" en [0,1,2,3,4]
    """
    distance_hamming = int(distance_hamming)
    liste_questions = list()
    liste_reponses = list()
    for id_question, reponse in request.args.items():
        liste_questions.append(int(id_question))
        liste_reponses.append(int(reponse))
    liste_filtre, liste_questions_posees = filter_liste_avec_question(liste_questions, liste_reponses, distance_hamming)
    """
        deduction correspond au titre de l'unique film de la liste filtree s'il y a encore
        plusieurs films ou aucun film dans la liste celui-ci prend la valeur par défault
        "AUCUNE".
    """
    deduction = "AUCUNE"
    id_deduit = -1
    if len(liste_filtre) == 1:
        deduction = liste_filtre[0].titre
        id_deduit = liste_filtre[0].id
    """
        reponse est le dictionnaire qu'on renvoie sous forme de JSON
    """
    id_question_selec, question_selec = question_ideale(liste_filtre, liste_questions_posees)
    reponse = {
        "id_deduction": id_deduit,
        "id_question": id_question_selec,
        "question": question_selec,
        "nombre_oeuvres_restantes": len(liste_filtre),
        "deduction": deduction
    }
    return jsonify(reponse)


@app.route('/bilan.html')
def get_bilan():
    return render_template("bilan.html")


@app.route('/api/v2.0/reponses/<id_film>')
def get_reponses_film(id_film):
    liste_questions = list()
    liste_reponses = list()
    for id_question, reponse in request.args.items():
        liste_questions.append(int(id_question))
        liste_reponses.append(int(reponse))
    return jsonify(reponse_attendu(liste_questions, id_film))


@app.route('/api/v2.0/film_ressemblant/')
@app.route('/api/v2.0/film_ressemblant/<debut_film>/<fin_film>')
def get_film_semblable(debut_film=0, fin_film=13):
    liste_questions = list()
    liste_reponses = list()
    for id_question, reponse in request.args.items():
        liste_questions.append(int(id_question))
        liste_reponses.append(int(reponse))
    liste_films = sort_liste_avec_question(liste_questions, liste_reponses)[debut_film:fin_film]
    liste_titre_films_a_retourner = list()
    liste_id_films_a_retourner = list()
    liste_date_films_a_retourner = list()
    for film in liste_films:
        liste_titre_films_a_retourner.append(film.titre)
        liste_id_films_a_retourner.append(film.id)
        liste_date_films_a_retourner.append(film.annee)
    """
        reponse est le dictionnaire qu'on renvoie sous forme de JSON
    """
    reponse = {
        "liste_titre": liste_titre_films_a_retourner,
        "liste_id": liste_id_films_a_retourner,
        # "liste_date": liste_date_films_a_retourner
    }
    return jsonify(reponse)


@app.errorhandler(404)
def not_found(error):
    return render_template('404.html'), 404


@app.errorhandler(400)
def bad_request(error):
    return make_response(jsonify({'erreur': "requete impossible"}))


@app.errorhandler(500)
def not_found(error):
    return render_template('500.html'), 500


if __name__ == '__main__':
    app.run()
