import unittest
from datamanager import *
from analysequestion import *


class TestAnalyseQuestion(unittest.TestCase):
    def setUp(self):
        self.liste_films = list()
        reponses1 = {1: 0, 2: 1, 3: 1, 4: 1, 5: 0, 6: 0}
        reponses2 = {1: 1, 2: 1, 3: 0, 4: 1, 5: 0, 6: 1}
        reponses3 = {1: 1, 2: 0, 3: 1, 4: 0, 5: 1, 6: 0}
        reponses4 = {1: 0, 2: 1, 3: 0, 4: 0, 5: 1, 6: 1}
        film1 = Film(id_film=1, titre="Film 1", compteur_oui=0, compteur_non=0, compteur_prob=0, compteur_prob_pas=0,
                     reponses=reponses1)
        film2 = Film(id_film=2, titre="Film 2", compteur_oui=0, compteur_non=0, compteur_prob=0, compteur_prob_pas=0,
                     reponses=reponses2)
        film3 = Film(id_film=3, titre="Film 3", compteur_oui=0, compteur_non=0, compteur_prob=0, compteur_prob_pas=0,
                     reponses=reponses3)
        film4 = Film(id_film=4, titre="Film 4", compteur_oui=0, compteur_non=0, compteur_prob=0, compteur_prob_pas=0,
                     reponses=reponses4)
        self.liste_films.append(film1)
        self.liste_films.append(film2)
        self.liste_films.append(film3)
        self.liste_films.append(film4)

    def test_frequenceoui(self):
        """
        Test la méthode frequenceoui avec la liste de films créer dans setUp
        Ce test doit compter le nombre de films ayant oui comme valeur pour
        chacunes des questions.
        """
        obtenu = frequence_oui(self.liste_films)
        attendu = {1: 2, 2: 3, 3: 2, 4: 2, 5: 2, 6: 2}
        self.assertDictEqual(obtenu, attendu)

    def test_question_maximisant_esperance(self):
        """
        Ce test vérifie que la fonction question_maximisant_esperance
        normalise bien le résultat de la fonction frequence_oui à par de
        l'esperance ideale ideale par question correspondant au nombre de
        films divisé par deux
        """
        obtenu = questions_maximisant_esperance(self.liste_films)
        attendu = {1: 0, 2: 1, 3: 0, 4: 0, 5: 0, 6: 0}
        self.assertDictEqual(obtenu, attendu)

    def test_question_ideale(self):
        """
        Ce test vérifie que la fonction question_idéale retourne bien
        la question avec le plus grand score normalisé à l'aide de la
        fonction question_maximisant_esperance
        Elle vérifie également que la question correspond à celle de la db
        pour cela nous utiliserons la db Akinator
        """
        attendu = (2,"Est-ce une oeuvre d'action ?")
        liste_question_deja_posee = list()
        obtenu = question_ideale(self.liste_films, liste_question_deja_posee)
        self.assertTupleEqual(attendu, attendu)

    def test_filter_carac(self):
        """
        Ce test vérifie que la fonction filter carac filtre bien avec une
        distance de hamming supérieur à 3
        """

        liste_questions_posees = [1,3,5,6]
        liste_reponses = [1,0,0,1]
        obtenu1 = filter_carac(self.liste_films[0],liste_questions_posees,liste_reponses)
        obtenu2 = filter_carac(self.liste_films[1], liste_questions_posees, liste_reponses)
        obtenu3 = filter_carac(self.liste_films[2], liste_questions_posees, liste_reponses)
        obtenu4 = filter_carac(self.liste_films[3], liste_questions_posees, liste_reponses)
        attendu1 = False
        attendu2 = True
        attendu3 = False
        attendu4 = True
        self.assertEqual(attendu1, obtenu1)
        self.assertEqual(attendu2, obtenu2)
        self.assertEqual(attendu3, obtenu3)
        self.assertEqual(attendu4, obtenu4)


if __name__ == '__main__':
    unittest.main()
