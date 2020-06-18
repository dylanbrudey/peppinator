"""Tests du module datamanager.py"""
from flask import Flask
import unittest
from tables_bdd import Oeuvre, Question, Reponse, PropositionOeuvre, PropositionQuestion, TraitementReponse, db
from datamanager import recuperer_questions, recuperer_oeuvres, ajouter_oeuvre_proposee, ajouter_question_proposee,\
    maj_element, supprimer_element, recuperer_reponse, maj_compteurs_reponse, recuperer_oeuvre_proposee, \
    recuperer_question_proposee, traiter_oeuvre_proposee, traiter_correction_proposee
import config_bdd


class TestDatamanager(unittest.TestCase):
    def setUp(self):
        """
        Créer une nouvelle base de données pour la réalisation des tests
        """
        self.app = Flask(__name__)
        self.app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = "False"
        self.app.config['SQLALCHEMY_DATABASE_URI'] = config_bdd.test_database_uri
        db.init_app(self.app)
        self.app.app_context().push()
        db.engine.execute("CREATE SCHEMA IF NOT EXISTS proposition")
        db.create_all()
        self.oeuvres_attendues = list()
        self.questions_attendues = list()
        self.reponses_attendues = list()
        self.oeuvres_prop_attendues = list()
        self.questions_prop_attendues = list()
        self.reponses_tr_attendues = list()
        self.ajouter_donnees_bdd(self.oeuvres_attendues, self.questions_attendues, self.reponses_attendues,
                                 self.oeuvres_prop_attendues, self.questions_prop_attendues, self.reponses_tr_attendues)

    def ajouter_donnees_bdd(self, oeuvres_att, questions_att, reponses_att,
                            oeuvres_p_att, questions_p_att, reponses_t_att):
        """
        Ajoute les données nécéssaires à la réalisation des tests à la base
        de données.
        :param reponses_t_att:
        :param questions_p_att:
        :param oeuvres_p_att:
        :param reponses_att:
        :param oeuvres_att: liste d'oeuvres attendues, se trouvant
        dans la base de données au début de chaque test
        :param questions_att: liste de questions attendues se trouvant dans
        la base de données au début de chaque test
        """
        db.session.rollback()
        # Ajout des objets Question dans la base de données et dans la
        # liste associée
        question = Question('Est-ce une série ?')
        question_2 = Question("Est-ce une oeuvre d'action ?")
        question_3 = Question('Est-ce un oeuvre d’horreur?')
        db.session.add(question)
        db.session.add(question_2)
        db.session.add(question_3)
        db.session.commit()
        questions_att.append(question)
        questions_att.append(question_2)
        questions_att.append(question_3)

        # Ajout des objets Oeuvre dans la base de données et dans la
        # liste associée
        oeuvre = Oeuvre('Joker', 2019)
        oeuvre_2 = Oeuvre('Fast and Furious', 2001)
        oeuvre_3 = Oeuvre('Skyfall', 2012)
        db.session.add(oeuvre)
        db.session.add(oeuvre_2)
        db.session.add(oeuvre_3)
        oeuvres_att.append(oeuvre)
        oeuvres_att.append(oeuvre_2)
        oeuvres_att.append(oeuvre_3)
        db.session.commit()

        # Ajout des objets Reponse dans la base de données et dans la
        # liste associée
        reponse = Reponse(1, 1, 0)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(1, 2, 0)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(1, 3, None)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(2, 1, 0)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(2, 2, 1)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(2, 3, 0)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(3, 1, None)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(3, 2, 1)
        reponses_att.append(reponse)
        db.session.add(reponse)
        reponse = Reponse(3, 3, 0)
        reponses_att.append(reponse)
        db.session.add(reponse)
        db.session.commit()

        # Ajout des objets PropositionOeuvre dans la base de données et dans la
        # liste associée
        oeuvre = PropositionOeuvre('Juno', 2007)
        oeuvre_2 = PropositionOeuvre('Toy Story 3', 2010)
        oeuvre_3 = PropositionOeuvre('Casino Royale', 2006)
        db.session.add(oeuvre)
        db.session.add(oeuvre_2)
        db.session.add(oeuvre_3)
        oeuvres_p_att.append(oeuvre)
        oeuvres_p_att.append(oeuvre_2)
        oeuvres_p_att.append(oeuvre_3)
        db.session.commit()

        # Ajout des objets PropositionQuestion dans la base de données et dans la
        # liste associée
        question = PropositionQuestion("Est-ce sorti avant 2005 ?")
        question_2 = PropositionQuestion("Est-ce une oeuvre comique ?")
        question_3 = PropositionQuestion('Est-ce un oeuvre de romance ?')
        db.session.add(question)
        db.session.add(question_2)
        db.session.add(question_3)
        db.session.commit()
        questions_p_att.append(question)
        questions_p_att.append(question_2)
        questions_p_att.append(question_3)

        # Ajout des objets TraitementReponse dans la base de données et dans la
        # liste associée
        reponse = TraitementReponse(id_oeuvre=1, id_question=1, reponse_proposee=True)
        reponses_t_att.append(reponse)
        db.session.add(reponse)
        reponse = TraitementReponse(id_oeuvre_p= 2, id_question=3, reponse_proposee=False)
        reponses_t_att.append(reponse)
        db.session.add(reponse)
        reponse = TraitementReponse(id_oeuvre=3, id_question_p=2, reponse_proposee=True)
        reponses_t_att.append(reponse)
        db.session.add(reponse)
        reponse = TraitementReponse(id_oeuvre_p=2, id_question_p=1, reponse_proposee=True)
        reponses_t_att.append(reponse)
        db.session.add(reponse)
        reponse = TraitementReponse(id_oeuvre_p=2, id_question=2, reponse_proposee=False)
        reponses_t_att.append(reponse)
        db.session.add(reponse)
        db.session.commit()

    def tearDown(self):
        """
        Ferme et supprime la session en cours, puis
        remet à zéro la base de données
        """
        db.session.remove()
        db.drop_all()

    def test_recuperer_questions(self):
        """
         Teste la méthode du même nom de la classe DataManager
         Récupère les questions présentes dans la base de données
         et les compare avec les questions que l'on a rentré dans
         cette dernière
        """
        obtenu = recuperer_questions()
        self.comparaison_liste_question(obtenu, self.questions_attendues)

    def test_recuperer_oeuvres(self):
        """
        Teste la méthode du même nom de la classe DataManager
        Permet de récupérer l'ensemble des films/séries se
        trouvant dans la base de données ou bien uniquement
        ceux à réponses incomplètes puis compare avec nos
        prédictions
        (paramètre 'reponses_correctes_completes' passé
        à False dans de cas là)
        """
        # Cas dans lequel on récupère toutes les oeuvres
        obtenu = recuperer_oeuvres(True)
        self.comparaison_liste_oeuvre(obtenu, self.oeuvres_attendues)
        # Cas dans lequel on ne récupère que les films à réponses incomplètes
        self.oeuvres_attendues.pop(1)
        obtenu_2 = recuperer_oeuvres(False)
        self.comparaison_liste_oeuvre(obtenu_2, self.oeuvres_attendues)

    def test_ajouter_oeuvre_proposee(self):
        """
        Ajoute des oeuvreq dans la base de données
        , puis récupère tous les oeuvres présents dans la
        base de données et les comparent aux oeuvres que
        l'on est supposé récupérer, soit les oeuvres qui viennent
        d'être ajouter ainsi que les oeuvres déjà présents dans la
        base de données
        """
        ajouter_oeuvre_proposee("Community", 2009)
        obtenu = recuperer_oeuvres()
        oeuvre_4 = Oeuvre('Community', 2009)
        oeuvre_4.id = 4
        self.oeuvres_attendues.append(oeuvre_4)
        self.comparaison_liste_oeuvre(obtenu, self.oeuvres_attendues)

    def test_ajouter_question_proposee(self):
        """
        Ajoute une question dans la base de données
        , puis récupère toutes les questions présentes dans la
        base de données et les comparent aux questions que
        l'on est supposé récupérer, soit les questions qui viennent
        d'être ajouter ainsi que les questions déjà présentes dans la
        base de données
        """
        ajouter_question_proposee("Est-ce toi que je vois à l'horizon ?")
        obtenu = recuperer_questions()
        question_4 = Question("Est-ce toi que je vois à l'horizon ?")
        question_4.id = 4
        self.questions_attendues.append(question_4)
        self.comparaison_liste_question(obtenu, self.questions_attendues)

    def test_supprimer_element(self):
        """
        Supprime des films dans la base de données,
        puis récupère ceux présentss dans la base de données
        et les comparent à ceux qui sont supposés être
        présents dans la base de données, soit tous les
        films à l'exception de ceux qui viennent d'être
        normalement supprimés
        """
        # Suppression d'une oeuvre
        oeuvre = db.session.query(Oeuvre).get(2)
        supprimer_element(oeuvre)
        obtenu = recuperer_oeuvres()
        self.oeuvres_attendues.pop(1)
        self.comparaison_liste_oeuvre(obtenu, self.oeuvres_attendues)
        # Suppression d'une question
        question = db.session.query(Question).get(3)
        obtenu = recuperer_questions()
        supprimer_element(question)
        self.questions_attendues.pop(2)
        self.comparaison_liste_question(obtenu, self.questions_attendues)

    def test_maj_element(self):
        """Mettre à jour une ligne dans la base de données
        Compare l'état original de la base de données avec
        celui après la mise à jour"""
        oeuvre = db.session.query(Oeuvre).get(1)
        oeuvre.titre_vo = "Le Clown"
        maj_element(oeuvre)
        oeuvre = db.session.query(Oeuvre).get(1)
        self.assertEqual(oeuvre.titre_vo, "Le Clown")

    def test_recuperer_reponse(self):
        """
        Récupère une réponse unique et la compare
        à la réponse originale donnée
        """
        obtenu = recuperer_reponse(1, 1)
        attendu = self.reponses_attendues[0]
        self.comparaison_liste_reponse([obtenu], [attendu])

    def test_recuperer_oeuvre_proposee(self):
        """
        Récupère une oeuvre proposée et la compare à
        l'original
        """
        obtenu = recuperer_oeuvre_proposee('Juno', 2007)
        attendu = self.oeuvres_prop_attendues[0]
        self.comparaison_liste_oeuvre_proposee([obtenu], [attendu])

    def test_recuperer_question_proposee(self):
        """
        Récupère une oeuvre proposée et la compare à
        l'original
        """
        obtenu = recuperer_question_proposee("Est-ce un oeuvre de romance ?")
        attendu = self.questions_prop_attendues[2]
        self.comparaison_liste_question_proposee([obtenu], [attendu])

    def test_traiter_correction_proposee(self):
        """
        Vérifie que les corrections sont bien envoyées aux tables de proposition
        dans la base de données
        """
        # Test doit réussir
        test = traiter_correction_proposee(id_oeuvre=2, id_question=2, reponse=True)
        self.assertTrue(test)
        # Test qui doit échouer : id_oeuvre = 5 n'existe pas
        test = traiter_correction_proposee(id_oeuvre=5, id_question=1, reponse=False)
        self.assertFalse(test)

    def test_traiter_oeuvre_proposee(self):
        """
        Vérifie que l'oeuvre proposée est éligible à être envoyée
        à la base de données
        """
        # Test doit réussir: nouvelle question
        reponses = dict()
        reponses[1] = True
        reponses[2] = True
        reponses[3] = False
        test = traiter_oeuvre_proposee(titre='Community', annee=2009, reponses=reponses,
                                       texte_nouv_question="Poule ou l'oeuf ?", choix_nouv_question=True)
        self.assertTrue(test)
        # Test doit réussir: sans nouvelle question
        test = traiter_oeuvre_proposee(titre='Goldeneye', annee=1995, reponses=reponses)
        self.assertTrue(test)
        # Test qui doit échouer : le choix ou le texte de la question n'est pas renseignée mais l'autre l'est
        test = traiter_oeuvre_proposee(titre='Skyfall', annee=2012, reponses=reponses,
                                       texte_nouv_question="Est-ce une série ayant plus de 5 saisons ?")
        self.assertFalse(test)
        test = traiter_oeuvre_proposee(titre='La Belle et la Bête', annee=1991,
                                       reponses=reponses, choix_nouv_question=True)
        self.assertFalse(test)

    def test_maj_compteurs_reponses(self):
        """
        Vérifie si la mise à jour des compteurs de réponses
        est fonctionnelle. Les compteurs existants sont identifiées
        de 0 à 4. Tout autre choix doit renvoyer False
        """
        # Test qui doit réussir
        choix = [0, 1, 2, 3, 4]
        reussite = True
        for un_choix in choix:
            if not maj_compteurs_reponse(1, 1, un_choix):
                reussite = False
        self.assertTrue(reussite)
        # Test qui doit échouer
        choix = [0, 1, 2, -1, 7]
        for un_choix in choix:
            if not maj_compteurs_reponse(1, 1, un_choix):
                reussite = False
        self.assertFalse(reussite)

    def comparaison_liste_oeuvre(self, obtenu, attendu):
        """
        Compare 2 listes d'oeuvres en vérifiant si
        chaque attribut est égal l'un l'autre
        :param obtenu: liste d'oeuvres obtenues en utilisant la fonction
        à tester
        :param attendu: liste d'oeuvres attendues comme résultat
        """
        self.assertTrue(obtenu)
        self.assertTrue(attendu)
        for oeuvre_ob, oeuvre_at in zip(obtenu, attendu):
            self.assertEqual(oeuvre_ob.id, oeuvre_at.id)
            self.assertEqual(oeuvre_ob.titre, oeuvre_at.titre)
            self.assertEqual(oeuvre_ob.score, oeuvre_at.score)
            self.assertEqual(oeuvre_ob.titre_vo, oeuvre_at.titre_vo)
            self.assertEqual(oeuvre_ob.annee, oeuvre_at.annee)

    def comparaison_liste_question(self, obtenu, attendu):
        """
        Compare 2 listes de questions en vérifiant si
        chaque attribut est égal l'un l'autre
        :param obtenu: liste de questions obtenues en utilisant la fonction
        à tester
        :param attendu: liste de questions attendues comme résultat
        """
        self.assertTrue(obtenu)
        self.assertTrue(attendu)
        for qu_ob, qu_at in zip(obtenu, attendu):
            self.assertEqual(qu_ob.texte, qu_at.texte)
            self.assertEqual(qu_ob.id, qu_at.id)

    def comparaison_liste_reponse(self, obtenu, attendu):
        """
        Compare 2 listes de réponses en vérifiant si
        chaque attribut est égal l'un l'autre
        :param obtenu: liste de réponses obtenues en utilisant la fonction
        à tester
        :param attendu: liste de réponses attendues comme résultat
        """
        self.assertTrue(obtenu)
        self.assertTrue(attendu)
        # Compare chaque attribut de chaque réponse à la même position dans chaque liste
        for reponse_ob, reponse_at in zip(obtenu, attendu):
            self.assertEqual(reponse_ob.id_oeuvre, reponse_at.id_oeuvre)
            self.assertEqual(reponse_ob.id_question, reponse_at.id_question)
            self.assertEqual(reponse_ob.reponse_correcte, reponse_at.reponse_correcte)
            self.assertEqual(reponse_ob.reponse_supposee, reponse_at.reponse_supposee)
            self.assertEqual(reponse_ob.nb_oui, reponse_at.nb_oui)
            self.assertEqual(reponse_ob.nb_non, reponse_at.nb_non)
            self.assertEqual(reponse_ob.nb_prob, reponse_at.nb_prob)
            self.assertEqual(reponse_ob.nb_prob_pas, reponse_at.nb_prob_pas)
            self.assertEqual(reponse_ob.nb_prob_pas, reponse_at.nb_prob_pas)

    def comparaison_liste_oeuvre_proposee(self, obtenu, attendu):
        """
        Compare 2 listes d'oeuvres proposées en vérifiant si
        chaque attribut est égal l'un l'autre
        :param obtenu: liste d'oeuvres obtenues en utilisant la fonction
        à tester
        :param attendu: liste d'oeuvres attendues comme résultat
        """
        self.assertTrue(obtenu)
        self.assertTrue(attendu)
        for oeuvre_ob, oeuvre_at in zip(obtenu, attendu):
            self.assertEqual(oeuvre_ob.id, oeuvre_at.id)
            self.assertEqual(oeuvre_ob.titre, oeuvre_at.titre)
            self.assertEqual(oeuvre_ob.annee, oeuvre_at.annee)
            self.assertEqual(oeuvre_ob.traite, oeuvre_at.traite)
            self.assertEqual(oeuvre_ob.priorite, oeuvre_at.priorite)
            self.assertEqual(oeuvre_ob.valide, oeuvre_at.valide)
            self.assertEqual(oeuvre_ob.date, oeuvre_at.date)

    def comparaison_liste_question_proposee(self, obtenu, attendu):
        """
        Compare 2 listes de questions en vérifiant si
        chaque attribut est égal l'un l'autre
        :param obtenu: liste de questions obtenues en utilisant la fonction
        à tester
        :param attendu: liste de questions attendues comme résultat
        """
        self.assertTrue(obtenu)
        self.assertTrue(attendu)
        for qu_ob, qu_at in zip(obtenu, attendu):
            self.assertEqual(qu_ob.texte, qu_at.texte)
            self.assertEqual(qu_ob.id, qu_at.id)
            self.assertEqual(qu_ob.traite, qu_at.traite)
            self.assertEqual(qu_ob.priorite, qu_at.priorite)
            self.assertEqual(qu_ob.valide, qu_at.valide)
            self.assertEqual(qu_ob.date, qu_at.date)