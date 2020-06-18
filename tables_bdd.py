"""Module traduisant les données présentes dans les tables de la base de données en utilisant des modèles
(SQLAlchemy) pour faciliter les requêtes et la manipulation de données"""

from flask_sqlalchemy import SQLAlchemy
from flask_admin.contrib.sqla import ModelView
from flask_admin.model import typefmt
from datetime import date

db = SQLAlchemy()


class Oeuvre(db.Model):
    """Permet de manipuler les données de type Oeuvre"""
    # Pas de id à assigner en cas de création d'une oeuvre,
    # la base de données gère automatiquement l'ajout
    def __init__(self, titre, annee, score=None):
        self.titre = titre
        self.annee = annee
        if score is not None:
            self.score = score
    # Représente les différents champs de la table dans la base de données ainsi que leurs types et contraintes
    # associés
    id = db.Column(db.Integer, primary_key=True)
    titre = db.Column(db.String(60), nullable=False)
    annee = db.Column(db.SmallInteger, nullable=False)
    titre_vo = db.Column(db.String(60))
    score = db.Column(db.Integer)

    db.UniqueConstraint(titre, annee)

    # Indique la relation entre les tables Oeuvre et Réponse (1 à N)
    reponses = db.relationship("Reponse", backref='oeuvre', cascade="all, delete")
    reponses_proposees = db.relationship("PropositionReponse", backref='oeuvre', cascade="all, delete")
    reponses_traitees = db.relationship("TraitementReponse", backref='oeuvre', cascade="all, delete")

    # Représentation de l'oeuvre
    def __repr__(self):
        return 'Oeuvre n°{} : {} ({})'.format(self.id, self.titre, self.annee)


class OeuvreView(ModelView):
    column_searchable_list = ['titre', 'annee']
    column_editable_list = ['titre', 'annee', 'titre_vo']
    column_display_pk = True


class Question(db.Model):
    """Permet de manipuler les données de type Question"""
    # Pas de id à assigner en cas de création d'une question,
    # la base de données gère automatiquement l'ajout
    def __init__(self, texte):
        self.texte = texte

    # Représente les différents champs de la table dans la base de données ainsi que leurs types et contraintes
    # associés
    id = db.Column(db.Integer, primary_key=True)
    texte = db.Column(db.String(60), unique=True, nullable=False)

    # Indique la relation entre les tables Question et Réponse (1 à N)
    reponses = db.relationship("Reponse", backref='question', cascade="all, delete")
    reponses_proposees = db.relationship("PropositionReponse", backref='question', cascade="all, delete")
    reponses_traitees = db.relationship("TraitementReponse", backref='question', cascade="all, delete")
    # Représentation de la question
    def __repr__(self):
        return 'Question : {} ({})'.format(self.texte, self.id)


class QuestionView(ModelView):
    column_searchable_list = ['texte']
    column_display_pk = True


class Reponse(db.Model):
    """Permet de manipuler les données de type Reponse"""
    # Bien qu'un constructeur est présent pour les tests, toute réponse doit être récupérer via
    # la base de données. Elles sont générées automatiquement lors de l'ajout
    # d'oeuvres ou de questions ainsi que supprimer de la même manière
    # (utilisation de trigger dans la base de données pour l'ajout,
    # DELETE CASCADE pour la suppression)
    def __init__(self, id_oeuvre, id_question, reponse_correcte):
        self.id_oeuvre = id_oeuvre
        self.id_question = id_question
        self.reponse_correcte = reponse_correcte

    # Représente les différents champs de la table dans la base de données ainsi que leurs types et contraintes
    # associés
    id_oeuvre = db.Column(db.Integer, db.ForeignKey("oeuvre.id", ondelete="CASCADE"), primary_key=True)
    id_question = db.Column(db.Integer, db.ForeignKey("question.id", ondelete="CASCADE"), primary_key=True)
    reponse_correcte = db.Column(db.Boolean)
    reponse_supposee = db.Column(db.Boolean)
    nb_oui = db.Column(db.Integer, default=0)
    nb_prob = db.Column(db.Integer, default=0)
    nb_prob_pas = db.Column(db.Integer, default=0)
    nb_non = db.Column(db.Integer, default=0)
    nb_ne_sais_pas = db.Column(db.Integer, default=0)

    # Représentation de la réponse
    def __repr__(self):
        if self.reponse_correcte is None and self.reponse_supposee is not None:
            return 'Réponse pour {} -> {} : {} (supposée)'.format(self.oeuvre, self.question, self.reponse_supposee)
        else:
            return 'Réponse pour {} -> {} : {}'.format(self.oeuvre, self.question, self.reponse_correcte)


class ReponseView(ModelView):
    column_display_pk = True
    column_searchable_list = ['id_oeuvre', 'id_question']


class PropositionOeuvre(db.Model):
    __tablename__ = 'oeuvre'
    __table_args__ = {"schema": "proposition", 'implicit_returning': False}

    def __init__(self, titre, annee, valide=None):
        self.titre = titre
        self.annee = annee
        self.valide = valide

    id = db.Column(db.Integer, primary_key=True)
    titre = db.Column(db.Text, nullable=False)
    annee = db.Column(db.SmallInteger, nullable=False)
    traite = db.Column(db.Boolean, nullable=False, default=False)
    priorite = db.Column(db.Integer, nullable=False, default=1)
    valide = db.Column(db.Boolean)
    date = db.Column(db.Date)
    # traiter date avec ajout NULL ici et dans bdd

    db.UniqueConstraint(titre, annee)

    reponses_traitees = db.relationship("TraitementReponse", backref='oeuvre_proposee', cascade="all, delete")

    # Représentation de l'oeuvre
    def __repr__(self):
        return 'Oeuvre n°{} : {} ({})'.format(self.id, self.titre, self.annee)


def date_format(view, value):
    return value.strftime('%d.%m.%Y')


# Source : Documentation at: https://flask-admin.readthedocs.io/en/latest/api/mod_model/
MY_DEFAULT_FORMATTERS = dict(typefmt.BASE_FORMATTERS)
MY_DEFAULT_FORMATTERS.update({
        type(None): typefmt.null_formatter,
        date: date_format
    })


class PropositionOeuvreView(ModelView):
    column_display_pk = True
    column_searchable_list = ['titre', 'annee']
    column_filters = ['priorite']
    column_type_formatters = MY_DEFAULT_FORMATTERS
    column_exclude_list = ['date']


class PropositionQuestion(db.Model):
    __tablename__ = 'question'
    __table_args__ = {"schema": "proposition", 'implicit_returning': False}

    def __init__(self, texte):
        self.texte = texte

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    texte = db.Column(db.Text, unique=True, nullable=False)
    traite = db.Column(db.Boolean, nullable=False, default=False)
    priorite = db.Column(db.Integer,nullable=False, default=1)
    valide = db.Column(db.Boolean)
    date = db.Column(db.Date)
    # traiter date avec ajout NULL ici et dans bdd
    reponses_traitees = db.relationship("TraitementReponse", backref='question_proposee', cascade="all, delete")

    # Représentation de la question
    def __repr__(self):
        return 'Question : {} ({})'.format(self.texte, self.id)


class PropositionQuestionView(ModelView):
    column_display_pk = True
    column_searchable_list = ['texte']
    column_filters = ['priorite']
    column_type_formatters = MY_DEFAULT_FORMATTERS
    column_exclude_list = ['date']


class TraitementReponse(db.Model):
    __tablename__ = 'traitement_reponse'
    __table_args__ = {"schema": "proposition", 'implicit_returning': False}

    def __init__(self, id_oeuvre=None, id_question=None, id_oeuvre_p=None, id_question_p=None, reponse_proposee=None):
        self.id_oeuvre = id_oeuvre
        self.id_question = id_question
        self.id_oeuvre_p = id_oeuvre_p
        self.id_question_p = id_question_p
        self.reponse_proposee = reponse_proposee

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_oeuvre = db.Column(db.Integer, db.ForeignKey("oeuvre.id", ondelete="CASCADE"))
    id_question = db.Column(db.Integer, db.ForeignKey("question.id", ondelete="CASCADE"))
    id_oeuvre_p = db.Column(db.Integer, db.ForeignKey("proposition.oeuvre.id", ondelete="CASCADE"))
    id_question_p = db.Column(db.Integer, db.ForeignKey("proposition.question.id", ondelete="CASCADE"))
    reponse_proposee = db.Column(db.Boolean, nullable=False)
    date = db.Column(db.Date)
    priorite = db.Column(db.Integer, nullable=False, default=1)
    # traiter date avec ajout NULL ici et dans bdd

    # Représentation de la réponse
    def __repr__(self):
        return 'Réponse pour {} -> {} : {}'.format(self.oeuvre, self.question, self.reponse_proposee)


class TraitementReponseView(ModelView):
    column_display_pk = True
    column_type_formatters = MY_DEFAULT_FORMATTERS
    column_exclude_list = ['date']


class PropositionReponse(db.Model):
    __tablename__ = 'reponse'
    __table_args__ = {"schema": "proposition"}
    id_oeuvre = db.Column(db.Integer, db.ForeignKey("oeuvre.id", ondelete="CASCADE"), primary_key=True)
    id_question = db.Column(db.Integer, db.ForeignKey("question.id", ondelete="CASCADE"), primary_key=True)
    reponse_proposee = db.Column(db.Boolean, nullable=False)
    traite = db.Column(db.Boolean, nullable=False, default=False)
    priorite = db.Column(db.Integer, nullable=False, default=1)
    valide = db.Column(db.Boolean)


class PropositionReponseView(ModelView):
    column_display_pk = True
    column_filters = ['priorite']
    column_type_formatters = MY_DEFAULT_FORMATTERS
    column_exclude_list = ['date']


