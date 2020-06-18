from tkinter import *

from analysequestion import questions_maximisant_esperance, question_ideale, filter_carac
from datamanager import DataManager, nom_fichier_bdd

"""
    Programme à utiliser dans un environnement de test ou de dévelloppement
    Ce programme est une interface graphique servant à tester les algorithme de tri
    ou bien à remplir la base de données des films pour le jeu Akinator.
"""


class SampleApp(Tk):
    def __init__(self):
        Tk.__init__(self)
        self._frame = None
        self.switch_frame(StartPage)

    def switch_frame(self, frame_class):
        new_frame = frame_class(self)
        if self._frame is not None:
            self._frame.destroy()
        self._frame = new_frame
        self._frame.pack()

    def switch_frame_arg(self, frame_class, arg1, arg2):
        new_frame = frame_class(self, arg1, arg2)
        if self._frame is not None:
            self._frame.destroy()
        self._frame = new_frame
        self._frame.pack()


class StartPage(Frame):
    def __init__(self, master):
        Frame.__init__(self, master)

        message_accueil = Label(self, text="Akinator", font=("Courrier", 40, "bold"), foreground="purple")
        message_accueil.grid(row=0, column=1, pady=30)

        bouton_jouer = Button(self, text="Jouer", width=20, height=5, command=lambda: master.switch_frame(PageJeu))
        bouton_jouer.grid(row=2, column=1, pady=150)

        bouton_ajouter = Button(self, text="Ajout", width=20, height=5,
                                command=lambda: master.switch_frame(PageAjoutAccueil))
        bouton_ajouter.grid(row=3, column=1)


class PageJeu(Frame):
    def __init__(self, master):
        Frame.__init__(self, master)
        Frame.configure(self)
        db = DataManager(nom_fichier_bdd)
        self.liste_film = db.recup_films_reponses()
        self.question_freq_absolue = questions_maximisant_esperance(self.liste_film)
        self.liste_questions_posee = list()
        self.liste_question_repondue = list()
        self.liste_reponse = list()
        self.liste_questions_posee.append(10)
        self.liste_questions_posee.append(11)
        self.question_ideale = question_ideale(self.liste_film, self.liste_questions_posee)
        self.liste_filtre = self.liste_film

        message_jeu = Label(self, text="Jeu", font=("Courrier", 30, "bold"), foreground="purple")
        message_jeu.grid(row=1, column=1)

        self.question = Label(self, text=self.question_ideale[1], pady=10)
        self.question.grid(row=2, column=1, pady=20)

        self.bouton_oui = Button(self, text="Oui", foreground="black", background="green", width=10, height=3,
                                 command=self.repondre_oui)
        self.bouton_oui.grid(row=3, column=1, padx=20)

        self.bouton_jsp = Button(self, text="Je ne sais pas", width=10, height=3, command=self.repondre_jsp)
        self.bouton_jsp.grid(row=4, column=1, padx=20)

        self.bouton_non = Button(self, text="Non", foreground="black", background="red", width=10, height=3,
                                 command=self.repondre_non)

        self.bouton_non.grid(row=5, column=1, padx=20)

        self.bouton_retour = Button(self, text="Retour", foreground="purple", background="pink",
                                    command=lambda: master.switch_frame(StartPage))
        self.bouton_retour.grid(row=0, column=0, padx=1, pady=5)

    # TODO vérifier qu'il reste des questions
    def repondre_oui(self):
        if not self.check_fin():
            self.liste_question_repondue.append(self.question_ideale[0])
            self.liste_reponse.append(0)
            self.liste_filtre = list(
                filter(lambda x: filter_carac(x, self.liste_question_repondue, self.liste_reponse), self.liste_filtre))
            print(self.liste_filtre)
            self.liste_questions_posee.append(self.question_ideale[0])
            self.question_ideale = question_ideale(self.liste_filtre, self.liste_questions_posee)
            self.question["text"] = self.question_ideale[1]
            self.check_fin()

    def repondre_non(self):
        if not self.check_fin():
            self.liste_question_repondue.append(self.question_ideale[0])
            self.liste_reponse.append(1)
            self.liste_filtre = list(
                filter(lambda x: filter_carac(x, self.liste_question_repondue, self.liste_reponse), self.liste_filtre))
            print(self.liste_filtre)
            self.liste_questions_posee.append(self.question_ideale[0])
            self.question_ideale = question_ideale(self.liste_filtre, self.liste_questions_posee)
            self.question["text"] = self.question_ideale[1]
            self.check_fin()

    def repondre_jsp(self):
        if not self.check_fin():
            self.liste_questions_posee.append(self.question_ideale[0])
            self.question_ideale = question_ideale(self.liste_filtre, self.liste_questions_posee)
            self.question["text"] = self.question_ideale[1]
            self.check_fin()

    def check_fin(self):
        if len(self.liste_filtre) > 1:
            return False
        else:
            self.question["text"] = "Tu pensais à " + self.liste_filtre[0].titre
            self.bouton_oui["state"] = "disabled"
            self.bouton_non["state"] = "disabled"
            self.bouton_jsp["state"] = "disabled"
            return True


class PageAjoutAccueil(Frame):
    def __init__(self, master):
        Frame.__init__(self, master)
        Frame.configure(self)
        self.message_accueil = Label(master,
                                     text="Veuillez rentrer la borne inferieur et superieur des id de films que vous aller remplir",
                                     foreground="purple")
        self.message_accueil.pack()

        self.entree_borne_inf = Entry(master, width=40, bd=10)
        self.entree_borne_inf.pack()

        self.entree_borne_sup = Entry(master, width=40, bd=10)
        self.entree_borne_sup.pack()

        bouton_valider = Button(self, text="Valider",
                                command=lambda: master.switch_frame_arg(PageAjout, int(self.entree_borne_inf.get()),
                                                                        int(self.entree_borne_sup.get())))
        bouton_valider.grid(row=2)


class PageAjout(Frame):
    def __init__(self, master, borne_inf, borne_sup):
        Frame.__init__(self, master)
        Frame.configure(self)
        self.db = DataManager(nom_fichier_bdd)
        self.borne_inf = borne_inf
        self.borne_sup = borne_sup
        self.nb_filmmax = borne_sup - borne_inf
        self.nb_filmfait = 0
        self.questions_non_repondue = self.db.recup_questions_non_repondues(borne_inf, borne_sup)
        self.cles_films = list()
        self.cles_questions = list()
        for (cle1, cle2) in self.questions_non_repondue.keys():
            self.cles_films.append(cle1)
            self.cles_questions.append(cle2)
        self.i_film = 0
        self.i_question = 0

        self.message_jeu = Label(self,
                                 text=self.questions_non_repondue.get((self.cles_films[0], self.cles_questions[0])),
                                 font=("Courrier", 12, "bold"),
                                 foreground="black")
        self.message_jeu.grid(row=1, column=1)

        self.bouton_oui = Button(self, text="Oui", foreground="black", background="green", width=10, height=3,
                                 command=self.repondre_oui)
        self.bouton_oui.grid(row=5, column=1, padx=20)

        self.bouton_non = Button(self, text="Non", foreground="black", background="red", width=10, height=3,
                                 command=self.repondre_non)
        self.bouton_non.grid(row=6, column=1, padx=20)

        self.bouton_retour = Button(self, text="Retour", foreground="purple", background="pink",
                                    command=lambda: master.switch_frame(StartPage))
        self.bouton_retour.grid(row=0, column=0, padx=1, pady=5)

    def repondre(self):
        if self.i_question + 1 >= len(self.cles_questions):
            self.i_question = 0
        if self.i_film + 1 >= len(self.cles_films):
            self.message_jeu["text"] = "Plus de questions !"
            self.db.ajouter_reponses(self.questions_non_repondue)
            self.bouton_oui["state"] = "disabled"
            self.bouton_non["state"] = "disabled"
        else:
            self.i_question += 1
            self.i_film += 1
            self.message_jeu["text"] = self.questions_non_repondue.get(
                (self.cles_films[self.i_film], self.cles_questions[self.i_question]))

    def repondre_oui(self):
        self.questions_non_repondue.get((self.cles_films[self.i_film], self.cles_questions[self.i_question])).append(1)
        self.repondre()

    def repondre_non(self):
        self.questions_non_repondue.get((self.cles_films[self.i_film], self.cles_questions[self.i_question])).append(0)
        self.repondre()


if __name__ == "__main__":
    app = SampleApp()
    app.geometry("768x680")
    app.mainloop()
