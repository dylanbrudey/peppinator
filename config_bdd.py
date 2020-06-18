"""Module de configuration de la base de données utilisant le module flask-SQLAlchemy
permet de créer l'uri de la base de données à attribuer à app.config['SQLALCHEMY_DATABASE_URI']"""


sgbd = 'postgresql'
# précisez le pilote si nécessaire en commencant la chaine par le caractère '+'
pilote = ''
nom_utilisateur = 'postgres'
mot_de_passe = '!!zoroark!!'
hote = 'localhost'
# précisez le port si nécessaire en commencant la chaine par le caractère ':'
port = ''
nom_bdd = 'polnareff_jp'
nom_bdd_test = 'test_peppinator'

database_uri = "{}{}://{}:{}@{}{}/{}".format(sgbd, pilote, nom_utilisateur, mot_de_passe, hote, port, nom_bdd)
test_database_uri = "{}{}://{}:{}@{}{}/{}".format(sgbd, pilote, nom_utilisateur, mot_de_passe, hote, port, nom_bdd_test)