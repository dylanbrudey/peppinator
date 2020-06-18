from tables_bdd import *
import sys
import traceback
from sqlalchemy.exc import DBAPIError, SQLAlchemyError, IntegrityError


def gerer_exception(erreur, complement=False):
    """
    Gère les exceptions lors d'une connexion à la base de données
    et annule toutes les transactions vers la base de données en cours
    :param complement: Complément d'information sur l'erreur si True
    :param erreur: Exception SQLAchemy à traiter
    """
    # Annule toutes les transactions vers la base de données en cours
    db.session.rollback()
    print("Erreur après accès à la base de données.")
    print("Voici cette dernière ainsi que sa classe : {} et {}\n".format(erreur.args, erreur.__class__))
    if complement:
        a_type, value, tracebk = sys.exc_info()
        print("Complément d'informations : \n")
        for i, exception in enumerate(traceback.format_exception(a_type, value, tracebk, chain=False)):
            if i > 0:
                print(exception, end='')


def recuperer_oeuvres(reponses_correctes_completes=True):
    """
        Récupère les films et séries de la base de données
        et optionnellement ceux non renseignés, c'est-à-dire, ne disposant pas
        d'une réponse à chaque question
        False si l'on souhaite uniquement récupérer les oeuvres à réponses incomplètes
        :return: itérateur d'objet Oeuvre
        """
    try:
        # Récupère toutes les oeuvres
        if reponses_correctes_completes:
            oeuvres = Oeuvre.query.all()
        # Récupère les oeuvres avec des réponses incomplètes
        else:
            # Remarque : La comparaison de reponse correcte avec None n'est pas une erreur mais
            # la façon correcte de comparer pour les requêtes SQL fabriquées avec SQLAlchemy
            oeuvres = Oeuvre.query.join(Reponse, Oeuvre.id == Reponse.id_oeuvre). \
                filter(Reponse.reponse_correcte == None).all()
    except (DBAPIError, SQLAlchemyError) as e:
        gerer_exception(e)
        raise DBAPIError("Aucune oeuvre récupérée", e.params, e.orig)
    else:
        return oeuvres
    finally:
        pass


def recuperer_questions():
    """
    Récupère les questions présentes dans la base de données
    :return: itérateur d'objet Question
    """
    try:
        # Récupère toutes les questions
        questions = Question.query.all()
    except (DBAPIError, SQLAlchemyError) as e:
        gerer_exception(e)
        raise DBAPIError("Aucune question récupérée", e.params, e.orig)
    else:
        return questions


def recuperer_reponse(id_oeuvre, id_question):
    """
    Récupère une unique réponse se trouvant dans la base de données
    :param id_question: l'id de la question de la réponse (int)
    :param id_oeuvre: l'id de l'oeuvre de la réponse (int)
    :return: la réponse (Reponse)
    """
    try:
        # Récupère une réponse
        reponse = Reponse.query.filter_by(id_oeuvre=id_oeuvre, id_question=id_question).first()
    except (DBAPIError, SQLAlchemyError) as e:
        gerer_exception(e)
        raise DBAPIError("Aucune reponse récupérée", e.params, e.orig)
    else:
        return reponse


def recuperer_oeuvre_proposee(titre, annee):
    """
    Récupère une oeuvre proposée à partir de son titre
    et de son année de parution
    :param titre: titre de l'oeuvre (str)
    :param annee: année de parution de l'oeuvre (int)
    :return: oeuvre recherché (PropositionOeuvre)
    """
    try:
        # Récupère une oeuvre proposée
        oeuvre_proposee = PropositionOeuvre.query.filter_by(titre=titre, annee=annee).first()
    except (DBAPIError, SQLAlchemyError) as e:
        gerer_exception(e)
        raise DBAPIError("Aucune reponse récupérée", e.params, e.orig)
    else:
        return oeuvre_proposee


def recuperer_question_proposee(texte):
    """
    Récupère une question proposée à partir de son
    texte
    :param texte: question (str)
    :return: question recherchée (PropositionQuestion)
    """
    try:
        # Récupère une question proposée
        question_proposee = PropositionQuestion.query.filter_by(texte=texte).first()
    except (DBAPIError, SQLAlchemyError) as e:
        gerer_exception(e)
        raise DBAPIError("Aucune reponse récupérée", e.params, e.orig)
    else:
        return question_proposee


def ajouter_oeuvre_proposee(titre, annee, valide=None):
    """
    Ajoute une oeuvre dans la base de données, vers les
    oeuvres valides ou dans les oeuvres proposées.
    :param valide: True si l'oeuvre a déjà été trouvée par l'api de films
    et séries (OMDBapi, avec possibles changements) (bool)
    :param titre: titre de l'oeuvre (str)
    :param annee: année de sortie de l'oeuvre (int)
    """
    # Si l'oeuvre est une oeuvre proposée par un utilisateur
    if valide:
        oeuvre = PropositionOeuvre(titre, annee)
    else:
        oeuvre = PropositionOeuvre(titre, annee, valide)
    # Ajoute l'élément dans la base de données
    __ajout_element(oeuvre)


def ajouter_question_proposee(texte):
    """
     Ajoute une réponse proposée par un utilisateur dans la base de données,
    dans une table de proposition
    :param texte: texte de la question (str)
    """
    question_proposee = PropositionQuestion(texte)
    __ajout_element(question_proposee)


def ajouter_reponse_proposee(id_oeuvre_proposee, id_question_proposee, oeuvre_existante, question_existante, reponse):
    """
    Ajoute une réponse proposée par un utilisateur dans la base de données,
    dans une table de traitement
    :param reponse: choix fait par l'utilisateur à la question
    :param question_existante: True si la question est déjà dans la base de données
    :param oeuvre_existante: True si l'oeuvre est déjà dans la base de données
    :param id_oeuvre_proposee: id de l'oeuvre liée à la réponse
    :param id_question_proposee: id de la question liée à la réponse
    :return: True si l'opération est un succès, False sinon
    """
    # Correction d'erreurs: l'oeuvre et la question sont déjà présentes dans la base de données
    if oeuvre_existante and question_existante:
        reponse_proposee = \
            TraitementReponse(id_oeuvre=id_oeuvre_proposee, id_question=id_question_proposee, reponse_proposee=reponse)
    elif oeuvre_existante and not question_existante:
        reponse_proposee = \
            TraitementReponse(id_oeuvre=id_oeuvre_proposee, id_question_p=id_question_proposee,
                              reponse_proposee=reponse)
    elif not oeuvre_existante and question_existante:
        reponse_proposee = \
            TraitementReponse(id_oeuvre_p=id_oeuvre_proposee, id_question=id_question_proposee,
                              reponse_proposee=reponse)
    # oeuvre_existante et question_existante valent None ou False
    else:
        reponse_proposee = \
            TraitementReponse(id_oeuvre_p=id_oeuvre_proposee, id_question_p=id_question_proposee,
                              reponse_proposee=reponse)
    retour = __ajout_element(reponse_proposee)
    return retour


def traiter_correction_proposee(id_oeuvre, id_question, reponse):
    """
    Traite les corrections proposées par l'utilisateur si ce dernier n'est pas
    en accord avec les réponses aux questions de l'oeuvre qu'il cherchait.
    Ces corrections sont envoyées dans nos tables de propositions dans
    lesquelles nous allons vérifier ces dernières.
    :param id_oeuvre: id de l'oeuvre que l'utilisateur recherchait (int)
    :param id_question: id de la question auquel l'utilisateur a répondu (int)
    :param reponse: réponse à la question pour le oeuvre recherchée
    :return: True si l'opération est un succès, False sinon
    """
    success = ajouter_reponse_proposee(id_oeuvre,
                                       id_question, oeuvre_existante=True, question_existante=True, reponse=reponse)
    return success


def traiter_oeuvre_proposee(titre, annee, reponses, texte_nouv_question=None, choix_nouv_question=None):
    """
    Traite l'oeuvre proposée par l'utilisateur ainsi qu'une nouvelle question
    dans certains cas.
    Lorsque une oeuvre est proposée, elle est toujours accompagnée par les
    réponses répondues par l'utilisateur qui sont elles aussi proposées.
    :param choix_nouv_question: réponse à la nouvelle question pour
    l'oeuvre (bool)
    :param texte_nouv_question: nouvelle question (str)
    :param reponses: dictionnaire de réponses avec les ID de questions
    commme clés
    :param annee: année de parution de la nouvelle oeuvre
    :param titre: titre de la nouvelle oeuvre
    :return: True si l'opération est un succès, False sinon
    """
    success = True
    ajouter_oeuvre_proposee(titre, annee)
    # Récupère l'oeuvre proposée avec son id
    oeuvre = recuperer_oeuvre_proposee(titre, annee)
    # Une nouvelle question a été proposée
    if texte_nouv_question is not None and choix_nouv_question is not None:
        ajouter_question_proposee(texte_nouv_question)
        # Récupère la question proposée avec son id
        nouvelle_question = recuperer_question_proposee(texte_nouv_question)
        # Ajoute la réponse avec la nouvelle question en premier
        if not ajouter_reponse_proposee(oeuvre.id,
                                        nouvelle_question.id, oeuvre_existante=False,
                                        question_existante=False, reponse=choix_nouv_question):
            success = False
    # Le texte de la question ou le choix de l'utilisateur de cette question est mal renseignée
    elif (texte_nouv_question is not None and choix_nouv_question is None) or (texte_nouv_question is None and
                                                                               choix_nouv_question is not None):
        print("Nouvelle question mal renseignée, l'oeuvre est potentiellement non distinguable\n d'une autre présente"
              " dans la base de données, l'oeuvre est refusée rétroactivement et les réponses non insérées")
        oeuvre.valide = False
        maj_element(oeuvre)
        return False
    # Ajoute toutes les suggestions de réponses
    for id_question, reponse in reponses.items():
        if not ajouter_reponse_proposee(oeuvre.id,
                                        id_question, oeuvre_existante=False, question_existante=True, reponse=reponse):
            success = False
    return success


def supprimer_element(element):
    """
    Supprime une oeuvre ou une question de la base de données.
    Ne peut supprimer les réponses. Cela est fait automatiquement
    lors de l'ajout/suppression des oeuvres et questions à l'aide d'un
    trigger posé sur la base de données.
    :param element: Objet Oeuvre ou Question à supprimer
    """
    if type(element) is Oeuvre or type(element) is Question:
        try:
            # Supprime l'oeuvre ou la question de la base de données
            db.session.delete(element)
            db.session.commit()
        # Erreur lors de la suppression
        except (DBAPIError, SQLAlchemyError) as e:
            print("{} n'a pas été supprimé(e) de la base de données".format(element))
            gerer_exception(e)
        else:
            print("{} a été supprimé(e) de la base de données".format(element))
    else:
        if element is Reponse:
            print("{} n'a pas été supprimé(e), les réponses ne peuvent être supprimées de la base de données de cette "
                  "manière. Elles sont uniquement supprimer quand l'oeuvre ou la question dont elle fait référence est "
                  "elle-même supprimée")
        else:
            print("{} n'appartient pas à cette base de données".format(element))


def __ajout_element(element):
    """
    Ajoute une oeuvre à la base de données.
    Peut aussi ajouter les oeuvres, questions et réponses
    proposées dans les tables de propositions de la base de données
    :param element: élément à ajouter à la base de données
    """
    try:
        # L'ajoute à la base de données
        db.session.add(element)
        db.session.commit()
    # Element déjà présent dans la base de données
    except IntegrityError as i:
        print("{} déjà présente dans la base de données".format(element))
        gerer_exception(i)
        return False
    except (DBAPIError, SQLAlchemyError) as erreur:
        gerer_exception(erreur)
        return False
    else:
        return True


def maj_element(element):
    """
    Met à jour dans la base de données un objet Oeuvre, Question
    ou Reponse
    :param element: objet Oeuvre, Question ou Reponse
    """
    try:
        db.session.commit()
    except (DBAPIError, SQLAlchemyError) as erreur:
        print("{} pas mise à jour".format(element))
        gerer_exception(erreur)
    else:
        print("{} mise à jour".format(element))


def maj_compteurs_reponse(id_oeuvre, id_question, choix):
    """
    Met à jour les compteurs d'une réponse à partir des choix
    fait par l'utilisateur au cours de la partie
    :param id_oeuvre: id de l'oeuvre cherchée (int)
    :param id_question: id de la question posée (int)
    :param choix: choix de la réponse à la question (int)
    :return: True si le choix est valide (compris entre 0 et 4), False sinon
    """
    # Récupère la réponse à mettre à jour dans la base de données
    reponse = recuperer_reponse(id_oeuvre, id_question)

    # Met à jour les compteurs en fonction de la réponse choisie par l'utilisateur

    # 'Non' a été répondu
    if choix == 0:
        reponse.nb_non += 1
    # 'Oui' a été répondu
    elif choix == 1:
        reponse.nb_oui += 1
    # 'Ne sais pas' à été répondu
    elif choix == 2:
        reponse.nb_ne_sais_pas += 1
    # 'Probablement' à été répondu
    elif choix == 3:
        reponse.nb_prob += 1
    # 'Probablement pas' à été répondu
    elif choix == 4:
        reponse.nb_prob_pas += 1
    else:
        print("le choix {} ne correspond à aucun des choix possibles".format(choix))
        return False
    # Commit les changements dans la base de données
    maj_element(reponse)
    return True
