from datamanager import recuperer_oeuvres, Question
from tables_bdd import Oeuvre

"""
Ce fichier contient les fonctions nécessaire à l'analyse des différentes liste de films.
"""


def question_ideale(liste_films, liste_questions_deja_posees):
    """
    Cette fonctionne trouve la question idéale parmi les question non posée en identifiant
    la question qui maximise l'espérance de la quantité d'information.
    :param liste_films: liste des films à trier
    :param liste_questions_deja_posees: liste des questions déjà posées
    :return: la question ideale sous forme de tuple (id_question (int),question (string))
    Todo:
        *Gestion des exceptions
    """
    """
       On récupère un dictionnaire des questions avec le score associé à chaque question
       (cf questions_maximisant_esperance)
       On trie ce dictionnaire et on renvoie la première question qui n'est pas dans la
       liste des questions déjà posées. Cette question est celle qui maximisera
       l'espérance de la quantité d'information.
    """

    question_freq_absolue = questions_maximisant_esperance(liste_films)
    question_sorted = sorted(question_freq_absolue, key=question_freq_absolue.get)
    for id_question in question_sorted:
        if id_question not in liste_questions_deja_posees:
            # Requête à la base de données : récupère la question avec l'id correspondant
            question_selec = Question.query.filter_by(id=id_question).first()
            return question_selec.id, question_selec.texte


def frequence_oui(liste_film):
    """
    Cette fonction utilitaire prend une liste de films et à partir des questions dans
    la base de données, compte le nombre de réponses "oui" par question
    :param liste_film: liste des films à filtrer
    :return: un dictionnaire avec {id_question: frequence_oui}
    TODO:
        *traiter les nombres oui/non/prob/prob pas
    """
    dictionnaire_frequence = {}
    for film in liste_film:
        for reponse in film.reponses:
            if reponse.reponse_correcte is not None:
                if reponse.id_question in dictionnaire_frequence:
                    dictionnaire_frequence[reponse.id_question] += reponse.reponse_correcte
                else:
                    dictionnaire_frequence[reponse.id_question] = reponse.reponse_correcte
    return dictionnaire_frequence


def questions_maximisant_esperance(liste_film):
    """
    A partir du dictionnaire de fréquence de oui établie un score correspondant
    à la valeur absolue de (l'espérance optimale - la quantité d'information de cette question)
    :param liste_film: liste de films à trier
    :return: dictionnaire de questions avec score {id_questions: score}
    """
    liste_de_frequence_oui_par_id_questions = frequence_oui(liste_film)
    nombre_de_films = len(liste_film)
    valeur_ideale = nombre_de_films / 2
    tab_valeur_absolue_difference = {}
    for id_question, freq in liste_de_frequence_oui_par_id_questions.items():
        tab_valeur_absolue_difference[id_question] = abs(valeur_ideale - freq)
    return tab_valeur_absolue_difference


def filter_carac(film, id_carac_posee, booleen_repondu, distance_hamming=1):
    """
    Fonction de tri en python fonctionnant pour la fonction standard filter associer à
    une fonction lamba afin d'utiliser des arguments.
    Le tri actuel s'effectue sur une distance de Hamming comparé aux réponses données
    par l'utilisateur au delà d'une distance de 2, correspondant à plus de 2 réponses
    discriminante on return false
    :param distance_hamming: distance à partir de laquelle nous filtrons un film
    :param film: Objet Film avec id_films, titre et reponses
    :param id_carac_posee:
    :param booleen_repondu:
    :return: True si on garde le film, False si on l'enlève
    """
    distance_de_hamming_max = distance_hamming
    reponse_discriminante = 0
    for reponse in film.reponses:
        i = 0
        nb_id_carac = len(id_carac_posee)
        while i < nb_id_carac:
            if reponse.id_question == id_carac_posee[i]:
                if booleen_repondu[i] == 2 or booleen_repondu[i] == 3 or booleen_repondu[i] == 4:
                    # TODO intégration nb oui non prob
                    pass
                elif not reponse.reponse_correcte == booleen_repondu[i]:
                    reponse_discriminante += 1
            i += 1
    if reponse_discriminante < distance_de_hamming_max:
        return True
    else:
        return False


def filter_liste(liste_reponses_api, distance_hamming=1):
    """
    Trie une liste de films à partir d'une liste de réponses.
    Cela permet de créer une API Stateless.
    On peut ainsi prédire les questions posées à partir de l'ordre des réponses données.
    :param distance_hamming:
    :param liste_reponses_api: liste d'entier correpondant aux répoonses données par l'utilisateur.
                Pour référence: 0 correspond à non
                                1 correspond à oui
                                2 correspond à je ne sais pas
                                3 correspond à probablement
                                4 correspond à probablement pas
    :return: tuple (liste_filtree, liste_questions_posees) correspondant à la liste
                des films restant et la liste des questions posees à partir de la liste des réponses
                données par l'utilisateur
    """
    liste_film = recuperer_oeuvres()
    liste_questions_repondues = list()
    liste_reponses_filtrante = list()
    liste_questions_posees = list()
    question = question_ideale(liste_film, liste_questions_posees)
    liste_filtre = liste_film
    for reponse in liste_reponses_api:
        liste_questions_repondues.append(question[0])
        if reponse == 0 or reponse == 1:  # 0 = non 1=oui 2=jsp 3=prb oui 4= prb pas si l'utilisateur ne sais pas on ne peut pas filtrer
            liste_reponses_filtrante.append(reponse)
            print(liste_filtre)
            liste_filtre = list(
                filter(lambda x: filter_carac(x, liste_questions_repondues, liste_reponses_filtrante, distance_hamming),
                       liste_filtre))
        liste_questions_posees.append(question[0])
        question = question_ideale(liste_filtre, liste_questions_posees)
    return liste_filtre, liste_questions_posees  # TODO renvoyer liste des questions posées


def filter_liste_avec_question(liste_questions, liste_reponses, distance_hamming=1):
    """
    Trie une liste de films à partir d'une liste de réponses.
    Cela permet de créer une API Stateless.
    On peut ainsi prédire les questions posées à partir de l'ordre des réponses données.
    :param distance_hamming:
    :param liste_reponses: liste d'entier correpondant aux répoonses données par l'utilisateur.
                Pour référence: 0 correspond à non
                                1 correspond à oui
                                2 correspond à je ne sais pas
                                3 correspond à probablement
                                4 correspond à probablement pas
    :return: tuple (liste_filtree, liste_questions_posees) correspondant à la liste
                des films restant et la liste des questions posees à partir de la liste des réponses
                données par l'utilisateur
    """
    liste_films = recuperer_oeuvres()
    liste_questions_posees = liste_questions[:]  # copié pas en référence
    liste_filtre = liste_films

    liste_filtre = list(
        filter(lambda x: filter_carac(x, liste_questions, liste_reponses, distance_hamming), liste_filtre))
    return liste_filtre, liste_questions_posees  # TODO renvoyer liste des questions posées


def sort_liste_avec_question(liste_questions, liste_reponses):
    liste_films = recuperer_oeuvres()
    liste_films = sorted(liste_films, key=lambda x: freq_occurante(x, liste_questions, liste_reponses), reverse=True)
    return sorted(liste_films, key=lambda x: distance_hamming_films_reponses(x, liste_questions, liste_reponses))


def distance_hamming_films_reponses(film, id_carac_posee, booleen_repondu):
    reponse_discriminante = 0
    for reponse in film.reponses:
        i = 0
        nb_id_carac = len(id_carac_posee)
        while i < nb_id_carac:
            if reponse.id_question == id_carac_posee[i]:
                if booleen_repondu[i] == 2 or booleen_repondu[i] == 3 or booleen_repondu[i] == 4:
                    # TODO intégration nb oui non prob
                    pass
                elif not reponse.reponse_correcte == booleen_repondu[i]:
                    reponse_discriminante += 1
            i += 1
    return reponse_discriminante


def freq_occurante(film, id_carac_posee, booleen_repondu):
    freq_occu = 0
    for reponse in film.reponses:
        i = 0
        nb_id_carac = len(id_carac_posee)
        while i < nb_id_carac:
            if reponse.id_question == id_carac_posee[i]:
                if booleen_repondu[i] == 2 or booleen_repondu[i] == 3 or booleen_repondu[i] == 4:
                    # TODO intégration nb oui non prob
                    pass
                elif reponse == booleen_repondu[i]:
                    freq_occu += 1
            i += 1
    return freq_occu


def reponse_attendu(liste_questions, id_film):
    film = Oeuvre.query.get(id_film)
    liste_des_reponses = film.reponses
    dict_reponses_attendues = dict()
    for reponse in liste_des_reponses:
        if reponse.id_question in liste_questions:
            dict_reponses_attendues[reponse.id_question] = reponse.reponse_correcte
    return dict_reponses_attendues


def top_question_non_repondues(liste_questions_deja_posees):
    liste_films = recuperer_oeuvres()
    question_freq_absolue = questions_maximisant_esperance(liste_films)
    question_sorted = sorted(question_freq_absolue, key=question_freq_absolue.get)
    liste_non_repondues = list()
    for id_question in question_sorted:
        if id_question not in liste_questions_deja_posees:
            # Requête à la base de données : récupère la question avec l'id correspondant
            liste_non_repondues.append(id_question)
    return liste_non_repondues
