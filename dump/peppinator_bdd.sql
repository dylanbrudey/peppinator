PGDMP             
            x           polnareff_jp    12.2    12.2 _    |           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            }           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ~           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                       1262    37134    polnareff_jp    DATABASE     �   CREATE DATABASE polnareff_jp WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'French_France.1252' LC_CTYPE = 'French_France.1252';
    DROP DATABASE polnareff_jp;
                postgres    false                        2615    37135    proposition    SCHEMA        CREATE SCHEMA proposition;
    DROP SCHEMA proposition;
                postgres    false            �            1255    37136    proposition_oeuvre()    FUNCTION     f  CREATE FUNCTION proposition.proposition_oeuvre() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF (TG_WHEN = 'BEFORE') THEN
			-- Vérifie si l'oeuvre ne se trouve pas déjà dans la base de données
			IF EXISTS(SELECT 1 FROM public.oeuvre WHERE NEW.titre = public.oeuvre.titre AND NEW.annee = public.oeuvre.annee) THEN
			RAISE EXCEPTION 'l''oeuvre %, % se trouve déjà dans la base de données',NEW.titre,NEW.annee;
			END IF;
			-- L'oeuvre a été trouvée par la recherche aves l'api de films et series (OMDBapi le 16.05.2020)
			IF (NEW.valide is true AND NEW.traite is false) THEN
				RAISE NOTICE 'trouvé dans l''api';
				INSERT INTO public.oeuvre (titre,annee) VALUES (NEW.titre,NEW.annee);
				NEW.traite := true;
			END IF;
			-- Vérifie si l'oeuvre se trouve déjà dans la table
			IF EXISTS (SELECT 1 FROM proposition.oeuvre WHERE NEW.titre = proposition.oeuvre.titre AND NEW.annee = proposition.oeuvre.annee) THEN
				UPDATE proposition.oeuvre SET priorite = priorite + 1 WHERE titre = NEW.titre AND annee = NEW.annee;
				RETURN NULL;
			END IF;
		END IF;
		-- L'oeuvre n'existe nulle part, on l'ajoute
		RETURN NEW;
	END IF;
	
	IF (TG_OP = 'UPDATE') THEN
		IF (TG_WHEN = 'AFTER') THEN 
			-- L'oeuvre est acceptée par le modérateur
			IF (NEW.valide is true AND NEW.traite is false) THEN
				RAISE NOTICE 'valide is true true';
				INSERT INTO public.oeuvre (titre,annee) VALUES (NEW.titre,NEW.annee);
			END IF;
		END IF;
		IF (NEW.valide is false AND NEW.traite is false) THEN
			RAISE NOTICE 'Watashi wa kita';
			NEW.traite := true;
			END IF;	
	RETURN NEW;
	END IF;
END$$;
 0   DROP FUNCTION proposition.proposition_oeuvre();
       proposition          postgres    false    6            �            1255    37137    proposition_question()    FUNCTION     �  CREATE FUNCTION proposition.proposition_question() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF (TG_OP = 'INSERT') THEN
		-- Vérifie si la question ne se trouve pas déjà dans la base de données
		IF EXISTS(SELECT 1 FROM public.question WHERE NEW.texte = public.question.texte) THEN
		RAISE EXCEPTION 'la question " % " se trouve déjà dans la base de données',NEW.texte;
		END IF;
		-- Vérifie si la question se trouve déjà dans la table
		IF EXISTS (SELECT 1 FROM proposition.question WHERE NEW.texte = proposition.question.texte) THEN
			UPDATE proposition.question SET priorite = proposition.question.priorite + 1 
			WHERE proposition.question.texte = NEW.texte;
			RETURN NULL;
		END IF;
		-- La question n'existe nulle part, on l'ajoute
		RETURN NEW;
	END IF;

	IF (TG_OP = 'UPDATE') THEN
		IF (TG_WHEN = 'AFTER') THEN 
			-- L'oeuvre est acceptée par le modérateur
			IF (NEW.valide is true AND NEW.traite is false) THEN
			RAISE NOTICE 'valide is true true';
				INSERT INTO public.question (texte) VALUES (NEW.texte);
			END IF;
		END IF;
		IF (NEW.valide is false AND NEW.traite is false) THEN
			RAISE NOTICE 'Watashi wa kita';
			NEW.traite := true;
			END IF;	
	RETURN NEW;
	END IF;
END$$;
 2   DROP FUNCTION proposition.proposition_question();
       proposition          postgres    false    6            �            1255    37138    proposition_reponse()    FUNCTION     �  CREATE FUNCTION proposition.proposition_reponse() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF (TG_OP = 'INSERT') THEN
		-- Vérifie si la question se trouve déjà dans la table
		IF EXISTS (SELECT 1 FROM proposition.reponse WHERE NEW.id_oeuvre = proposition.reponse.id_oeuvre
				  AND NEW.id_question = proposition.reponse.id_question) THEN
			UPDATE proposition.reponse SET priorite = proposition.reponse.priorite + NEW.priorite 
			WHERE NEW.id_oeuvre = proposition.reponse.id_oeuvre
			AND NEW.id_question = proposition.reponse.id_question;
			RETURN NULL;
		END IF;
		-- La question n'existe nulle part, on l'ajoute
		RETURN NEW;
	END IF;
	
	IF(TG_OP = 'UPDATE') THEN
			IF (TG_WHEN = 'AFTER') THEN
				-- Met à jour la réponse dans la base de données (table public.reponse) 
				IF (NEW.valide is true AND NEW.traite is false) THEN
						RAISE NOTICE 'valide is true true';
						UPDATE public.reponse SET reponse_correcte = NEW.reponse_proposee
						WHERE id_oeuvre = NEW.id_oeuvre 
						AND id_question = NEW.id_question;
					-- Marque la reponse comme traitée
					NEW.traite := true;
				END IF;
			END IF;
			IF (NEW.valide is NOT NULL AND NEW.traite is false) THEN
					NEW.traite := true;
				END IF;
				RETURN NEW;
		END IF;
END;$$;
 1   DROP FUNCTION proposition.proposition_reponse();
       proposition          postgres    false    6            �            1255    37139    traitement_reponse()    FUNCTION     L  CREATE FUNCTION proposition.traitement_reponse() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF (TG_WHEN = 'BEFORE') THEN
			-- La réponse est déjà identifiée dans la base de données
			-- par une oeuvre et une question, on l'ajoute aux réponses proposables
			IF NEW.id_oeuvre is not NULL AND NEW.id_question is not NULL THEN
				INSERT INTO proposition.reponse (id_oeuvre,id_question,reponse_proposee)
				VALUES (NEW.id_oeuvre, NEW.id_question,NEW.reponse_proposee);
			END IF;
			-- La réponse est déjà présente dans la table et non traitée -> augmente sa priorité
			IF EXISTS 
				(SELECT 1 FROM proposition.traitement_reponse as tr_rep WHERE 
				 (NEW.id_oeuvre_p = tr_rep.id_oeuvre_p AND NEW.id_question = tr_rep.id_question)
				OR (NEW.id_oeuvre = tr_rep.id_oeuvre AND NEW.id_question_p = tr_rep.id_question_p)
				OR (NEW.id_oeuvre_p = tr_rep.id_oeuvre_p AND NEW.id_question_p = tr_rep.id_question_p))
			THEN
				UPDATE proposition.traitement_reponse SET priorite = traitement_reponse.priorite + 1 
				WHERE (NEW.id_oeuvre_p = id_oeuvre_p AND NEW.id_question = id_question)
				OR (NEW.id_oeuvre = id_oeuvre AND NEW.id_question_p = id_question_p)
				OR (NEW.id_oeuvre_p = id_oeuvre_p AND NEW.id_question_p = id_question_p);
				RETURN NULL;
			END IF;
			-- La réponse n'est pas présente dans la table -> insertion
			RETURN NEW;
		END IF;
	END IF;
	
	IF (TG_OP = 'UPDATE') THEN
			-- La réponse est finalement identifiée dans la base de données
			-- par une oeuvre et une question, on l'ajoute aux réponses proposables
			IF NEW.id_oeuvre is not NULL AND NEW.id_question is not NULL THEN
				INSERT INTO proposition.reponse (id_oeuvre,id_question,reponse_proposee,priorite)
				VALUES (NEW.id_oeuvre, NEW.id_question,NEW.reponse_proposee,NEW.priorite);
			END IF;
			RETURN NEW;
	END IF;
END$$;
 0   DROP FUNCTION proposition.traitement_reponse();
       proposition          postgres    false    6            �            1255    37140    insert_reponse_from_oeuvre()    FUNCTION     W  CREATE FUNCTION public.insert_reponse_from_oeuvre() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
INSERT INTO reponse (id_oeuvre, id_question) 
        SELECT oeuvre.id as id_oeuvre, question.id as id_question FROM oeuvre,question 
		WHERE oeuvre.id NOT IN(SELECT DISTINCT id_oeuvre 
		FROM reponse)
		ORDER BY 1;
		RETURN NULL;
END;$$;
 3   DROP FUNCTION public.insert_reponse_from_oeuvre();
       public          postgres    false            �            1255    37141    insert_reponse_from_question()    FUNCTION     ^  CREATE FUNCTION public.insert_reponse_from_question() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
INSERT INTO reponse (id_oeuvre, id_question)  
        SELECT oeuvre.id as id_oeuvre, question.id as id_question FROM oeuvre,question 
		WHERE question.id NOT IN(SELECT DISTINCT id_question 
		FROM reponse)
		ORDER BY 1;
		RETURN NULL;
END;$$;
 5   DROP FUNCTION public.insert_reponse_from_question();
       public          postgres    false            �            1255    37142 )   insert_update_traitement_reponse_oeuvre()    FUNCTION     �  CREATE FUNCTION public.insert_update_traitement_reponse_oeuvre() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	--Valide l'oeuvre en tant qu'oeuvre acceptée dans les réponses liées se trouvant dans traitement_reponse
			UPDATE proposition.traitement_reponse SET id_oeuvre = NEW.id
			WHERE id_oeuvre_p = (SELECT p_o.id FROM proposition.oeuvre p_o WHERE titre = NEW.titre AND
										   annee = NEW.annee);
	--Passe l'oeuvre dans la table de proposition comme traitée
			UPDATE proposition.oeuvre SET traite = true
			WHERE traite IS false 
			AND valide IS NOT NULL;
	--REVOIR la suite si bug, dernière chose faite le 15/16 mai
			RETURN NULL;
END
$$;
 @   DROP FUNCTION public.insert_update_traitement_reponse_oeuvre();
       public          postgres    false            �           0    0 2   FUNCTION insert_update_traitement_reponse_oeuvre()    COMMENT     i   COMMENT ON FUNCTION public.insert_update_traitement_reponse_oeuvre() IS 'TRIGGER : INSERT AFTER Oeuvre';
          public          postgres    false    234            �            1255    37143 +   insert_update_traitement_reponse_question()    FUNCTION     g  CREATE FUNCTION public.insert_update_traitement_reponse_question() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	--Valide la question en tant que question acceptée dans les réponses liées se trouvant dans traitement_reponse
			UPDATE proposition.traitement_reponse SET id_question = NEW.id
			WHERE id_question_p = (SELECT p_q.id FROM proposition.question p_q WHERE texte = NEW.texte);
	--Passe la question dans la table de proposition comme traitée
			UPDATE proposition.question SET traite = true
			WHERE traite IS false 
			AND valide IS NOT NULL;
			--Revoir la suite si bug
			RETURN NULL;
END
$$;
 B   DROP FUNCTION public.insert_update_traitement_reponse_question();
       public          postgres    false            �            1255    37144    no_insert_delete_reponse()    FUNCTION     N  CREATE FUNCTION public.no_insert_delete_reponse() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
        RAISE EXCEPTION
            'Ajout ou la suppression de lignes
			dans réponses n est pas autorisé(e),
			cette opération est faite automatiquement
			lors des ajouts/suppressions de oeuvres
			ou de questions';
END;$$;
 1   DROP FUNCTION public.no_insert_delete_reponse();
       public          postgres    false            �            1259    37145    oeuvre    TABLE     �   CREATE TABLE proposition.oeuvre (
    id integer NOT NULL,
    titre text NOT NULL,
    annee smallint NOT NULL,
    traite boolean DEFAULT false NOT NULL,
    valide boolean,
    priorite integer DEFAULT 1 NOT NULL,
    date date
);
    DROP TABLE proposition.oeuvre;
       proposition         heap    postgres    false    6            �            1259    37153    oeuvre_id_seq    SEQUENCE     �   CREATE SEQUENCE proposition.oeuvre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE proposition.oeuvre_id_seq;
       proposition          postgres    false    203    6            �           0    0    oeuvre_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE proposition.oeuvre_id_seq OWNED BY proposition.oeuvre.id;
          proposition          postgres    false    204            �            1259    37155    question    TABLE     �   CREATE TABLE proposition.question (
    id integer NOT NULL,
    texte text NOT NULL,
    traite boolean DEFAULT false NOT NULL,
    valide boolean,
    priorite integer DEFAULT 1 NOT NULL,
    date date
);
 !   DROP TABLE proposition.question;
       proposition         heap    postgres    false    6            �            1259    37163    question_id_seq    SEQUENCE     �   CREATE SEQUENCE proposition.question_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE proposition.question_id_seq;
       proposition          postgres    false    6    205            �           0    0    question_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE proposition.question_id_seq OWNED BY proposition.question.id;
          proposition          postgres    false    206            �            1259    37165    reponse    TABLE     �   CREATE TABLE proposition.reponse (
    id_oeuvre integer NOT NULL,
    id_question integer NOT NULL,
    reponse_proposee boolean NOT NULL,
    traite boolean DEFAULT false NOT NULL,
    priorite integer DEFAULT 1 NOT NULL,
    valide boolean
);
     DROP TABLE proposition.reponse;
       proposition         heap    postgres    false    6            �            1259    37170    traitement_reponse    TABLE       CREATE TABLE proposition.traitement_reponse (
    id integer NOT NULL,
    id_oeuvre integer,
    id_question integer,
    id_oeuvre_p integer,
    id_question_p integer,
    reponse_proposee boolean NOT NULL,
    date date,
    priorite integer DEFAULT 1 NOT NULL
);
 +   DROP TABLE proposition.traitement_reponse;
       proposition         heap    postgres    false    6            �            1259    37173    traitement_reponse_id_seq    SEQUENCE     �   CREATE SEQUENCE proposition.traitement_reponse_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE proposition.traitement_reponse_id_seq;
       proposition          postgres    false    6    208            �           0    0    traitement_reponse_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE proposition.traitement_reponse_id_seq OWNED BY proposition.traitement_reponse.id;
          proposition          postgres    false    209            �            1259    37175    oeuvre    TABLE     �   CREATE TABLE public.oeuvre (
    id integer NOT NULL,
    titre text NOT NULL,
    score integer,
    titre_vo text,
    annee smallint NOT NULL
);
    DROP TABLE public.oeuvre;
       public         heap    postgres    false            �           0    0    COLUMN oeuvre.id    COMMENT     /   COMMENT ON COLUMN public.oeuvre.id IS 'TRIAL';
          public          postgres    false    210            �           0    0    COLUMN oeuvre.titre    COMMENT     2   COMMENT ON COLUMN public.oeuvre.titre IS 'TRIAL';
          public          postgres    false    210            �           0    0    COLUMN oeuvre.score    COMMENT     2   COMMENT ON COLUMN public.oeuvre.score IS 'TRIAL';
          public          postgres    false    210            �            1259    37181    oeuvre_id_seq    SEQUENCE     �   CREATE SEQUENCE public.oeuvre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.oeuvre_id_seq;
       public          postgres    false    210            �           0    0    oeuvre_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.oeuvre_id_seq OWNED BY public.oeuvre.id;
          public          postgres    false    211            �            1259    37183    question    TABLE     S   CREATE TABLE public.question (
    id integer NOT NULL,
    texte text NOT NULL
);
    DROP TABLE public.question;
       public         heap    postgres    false            �           0    0    COLUMN question.id    COMMENT     1   COMMENT ON COLUMN public.question.id IS 'TRIAL';
          public          postgres    false    212            �           0    0    COLUMN question.texte    COMMENT     4   COMMENT ON COLUMN public.question.texte IS 'TRIAL';
          public          postgres    false    212            �            1259    37189    question_id_seq    SEQUENCE     �   CREATE SEQUENCE public.question_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.question_id_seq;
       public          postgres    false    212            �           0    0    question_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.question_id_seq OWNED BY public.question.id;
          public          postgres    false    213            �            1259    37191    reponse    TABLE     P  CREATE TABLE public.reponse (
    id_oeuvre integer NOT NULL,
    id_question integer NOT NULL,
    reponse_correcte boolean DEFAULT false,
    nb_oui integer DEFAULT 0,
    nb_prob integer DEFAULT 0,
    nb_prob_pas integer DEFAULT 0,
    nb_non integer DEFAULT 0,
    reponse_supposee boolean,
    nb_ne_sais_pas integer DEFAULT 0
);
    DROP TABLE public.reponse;
       public         heap    postgres    false            �           0    0    COLUMN reponse.id_oeuvre    COMMENT     7   COMMENT ON COLUMN public.reponse.id_oeuvre IS 'TRIAL';
          public          postgres    false    214            �           0    0    COLUMN reponse.id_question    COMMENT     9   COMMENT ON COLUMN public.reponse.id_question IS 'TRIAL';
          public          postgres    false    214            �           0    0    COLUMN reponse.reponse_correcte    COMMENT     >   COMMENT ON COLUMN public.reponse.reponse_correcte IS 'TRIAL';
          public          postgres    false    214            �            1259    37200    reponse_id_oeuvre_seq    SEQUENCE     �   CREATE SEQUENCE public.reponse_id_oeuvre_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.reponse_id_oeuvre_seq;
       public          postgres    false    214            �           0    0    reponse_id_oeuvre_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.reponse_id_oeuvre_seq OWNED BY public.reponse.id_oeuvre;
          public          postgres    false    215            �
           2604    37202 	   oeuvre id    DEFAULT     p   ALTER TABLE ONLY proposition.oeuvre ALTER COLUMN id SET DEFAULT nextval('proposition.oeuvre_id_seq'::regclass);
 =   ALTER TABLE proposition.oeuvre ALTER COLUMN id DROP DEFAULT;
       proposition          postgres    false    204    203            �
           2604    37203    question id    DEFAULT     t   ALTER TABLE ONLY proposition.question ALTER COLUMN id SET DEFAULT nextval('proposition.question_id_seq'::regclass);
 ?   ALTER TABLE proposition.question ALTER COLUMN id DROP DEFAULT;
       proposition          postgres    false    206    205            �
           2604    37204    traitement_reponse id    DEFAULT     �   ALTER TABLE ONLY proposition.traitement_reponse ALTER COLUMN id SET DEFAULT nextval('proposition.traitement_reponse_id_seq'::regclass);
 I   ALTER TABLE proposition.traitement_reponse ALTER COLUMN id DROP DEFAULT;
       proposition          postgres    false    209    208            �
           2604    37205 	   oeuvre id    DEFAULT     f   ALTER TABLE ONLY public.oeuvre ALTER COLUMN id SET DEFAULT nextval('public.oeuvre_id_seq'::regclass);
 8   ALTER TABLE public.oeuvre ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    211    210            �
           2604    37206    question id    DEFAULT     j   ALTER TABLE ONLY public.question ALTER COLUMN id SET DEFAULT nextval('public.question_id_seq'::regclass);
 :   ALTER TABLE public.question ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    213    212            �
           2604    37207    reponse id_oeuvre    DEFAULT     v   ALTER TABLE ONLY public.reponse ALTER COLUMN id_oeuvre SET DEFAULT nextval('public.reponse_id_oeuvre_seq'::regclass);
 @   ALTER TABLE public.reponse ALTER COLUMN id_oeuvre DROP DEFAULT;
       public          postgres    false    215    214            m          0    37145    oeuvre 
   TABLE DATA           W   COPY proposition.oeuvre (id, titre, annee, traite, valide, priorite, date) FROM stdin;
    proposition          postgres    false    203   ��       o          0    37155    question 
   TABLE DATA           R   COPY proposition.question (id, texte, traite, valide, priorite, date) FROM stdin;
    proposition          postgres    false    205   ϒ       q          0    37165    reponse 
   TABLE DATA           j   COPY proposition.reponse (id_oeuvre, id_question, reponse_proposee, traite, priorite, valide) FROM stdin;
    proposition          postgres    false    207   �       r          0    37170    traitement_reponse 
   TABLE DATA           �   COPY proposition.traitement_reponse (id, id_oeuvre, id_question, id_oeuvre_p, id_question_p, reponse_proposee, date, priorite) FROM stdin;
    proposition          postgres    false    208   	�       t          0    37175    oeuvre 
   TABLE DATA           C   COPY public.oeuvre (id, titre, score, titre_vo, annee) FROM stdin;
    public          postgres    false    210   &�       v          0    37183    question 
   TABLE DATA           -   COPY public.question (id, texte) FROM stdin;
    public          postgres    false    212   �       x          0    37191    reponse 
   TABLE DATA           �   COPY public.reponse (id_oeuvre, id_question, reponse_correcte, nb_oui, nb_prob, nb_prob_pas, nb_non, reponse_supposee, nb_ne_sais_pas) FROM stdin;
    public          postgres    false    214   ��       �           0    0    oeuvre_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('proposition.oeuvre_id_seq', 24, true);
          proposition          postgres    false    204            �           0    0    question_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('proposition.question_id_seq', 24, true);
          proposition          postgres    false    206            �           0    0    traitement_reponse_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('proposition.traitement_reponse_id_seq', 200, true);
          proposition          postgres    false    209            �           0    0    oeuvre_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.oeuvre_id_seq', 132, true);
          public          postgres    false    211            �           0    0    question_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.question_id_seq', 95, true);
          public          postgres    false    213            �           0    0    reponse_id_oeuvre_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.reponse_id_oeuvre_seq', 109, true);
          public          postgres    false    215            �
           2606    37209    oeuvre proposition_oeuvre_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY proposition.oeuvre
    ADD CONSTRAINT proposition_oeuvre_pkey PRIMARY KEY (id);
 M   ALTER TABLE ONLY proposition.oeuvre DROP CONSTRAINT proposition_oeuvre_pkey;
       proposition            postgres    false    203            �
           2606    37211 "   question proposition_question_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY proposition.question
    ADD CONSTRAINT proposition_question_pkey PRIMARY KEY (id);
 Q   ALTER TABLE ONLY proposition.question DROP CONSTRAINT proposition_question_pkey;
       proposition            postgres    false    205            �
           2606    37213     reponse proposition_reponse_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY proposition.reponse
    ADD CONSTRAINT proposition_reponse_pkey PRIMARY KEY (id_oeuvre, id_question);
 O   ALTER TABLE ONLY proposition.reponse DROP CONSTRAINT proposition_reponse_pkey;
       proposition            postgres    false    207    207            �
           2606    37215 *   traitement_reponse traitement_reponse_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY proposition.traitement_reponse
    ADD CONSTRAINT traitement_reponse_pkey PRIMARY KEY (id);
 Y   ALTER TABLE ONLY proposition.traitement_reponse DROP CONSTRAINT traitement_reponse_pkey;
       proposition            postgres    false    208            �
           2606    37217    question unique_texte 
   CONSTRAINT     V   ALTER TABLE ONLY proposition.question
    ADD CONSTRAINT unique_texte UNIQUE (texte);
 D   ALTER TABLE ONLY proposition.question DROP CONSTRAINT unique_texte;
       proposition            postgres    false    205            �
           2606    37219    oeuvre unique_titre_annee 
   CONSTRAINT     a   ALTER TABLE ONLY proposition.oeuvre
    ADD CONSTRAINT unique_titre_annee UNIQUE (titre, annee);
 H   ALTER TABLE ONLY proposition.oeuvre DROP CONSTRAINT unique_titre_annee;
       proposition            postgres    false    203    203            �
           2606    37221    oeuvre film_serie_pk 
   CONSTRAINT     R   ALTER TABLE ONLY public.oeuvre
    ADD CONSTRAINT film_serie_pk PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.oeuvre DROP CONSTRAINT film_serie_pk;
       public            postgres    false    210            �
           2606    37223    question question_pk 
   CONSTRAINT     R   ALTER TABLE ONLY public.question
    ADD CONSTRAINT question_pk PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.question DROP CONSTRAINT question_pk;
       public            postgres    false    212            �
           2606    37225 #   reponse sqlite_autoindex_repond_a_1 
   CONSTRAINT     u   ALTER TABLE ONLY public.reponse
    ADD CONSTRAINT sqlite_autoindex_repond_a_1 PRIMARY KEY (id_oeuvre, id_question);
 M   ALTER TABLE ONLY public.reponse DROP CONSTRAINT sqlite_autoindex_repond_a_1;
       public            postgres    false    214    214            �
           2606    37227    question texte 
   CONSTRAINT     J   ALTER TABLE ONLY public.question
    ADD CONSTRAINT texte UNIQUE (texte);
 8   ALTER TABLE ONLY public.question DROP CONSTRAINT texte;
       public            postgres    false    212            �
           2606    37229    oeuvre titre_annee 
   CONSTRAINT     U   ALTER TABLE ONLY public.oeuvre
    ADD CONSTRAINT titre_annee UNIQUE (titre, annee);
 <   ALTER TABLE ONLY public.oeuvre DROP CONSTRAINT titre_annee;
       public            postgres    false    210    210            �
           2620    37230 (   oeuvre trigger_proposition_oeuvre_insert    TRIGGER     �   CREATE TRIGGER trigger_proposition_oeuvre_insert BEFORE INSERT ON proposition.oeuvre FOR EACH ROW WHEN ((pg_trigger_depth() = 0)) EXECUTE FUNCTION proposition.proposition_oeuvre();
 F   DROP TRIGGER trigger_proposition_oeuvre_insert ON proposition.oeuvre;
       proposition          postgres    false    235    203            �
           2620    37231 .   oeuvre trigger_proposition_oeuvre_update_after    TRIGGER     �   CREATE TRIGGER trigger_proposition_oeuvre_update_after AFTER UPDATE ON proposition.oeuvre FOR EACH ROW EXECUTE FUNCTION proposition.proposition_oeuvre();
 L   DROP TRIGGER trigger_proposition_oeuvre_update_after ON proposition.oeuvre;
       proposition          postgres    false    203    235            �
           2620    37232 /   oeuvre trigger_proposition_oeuvre_update_before    TRIGGER     �   CREATE TRIGGER trigger_proposition_oeuvre_update_before BEFORE UPDATE ON proposition.oeuvre FOR EACH ROW EXECUTE FUNCTION proposition.proposition_oeuvre();
 M   DROP TRIGGER trigger_proposition_oeuvre_update_before ON proposition.oeuvre;
       proposition          postgres    false    203    235            �
           2620    37233 ,   question trigger_proposition_question_insert    TRIGGER     �   CREATE TRIGGER trigger_proposition_question_insert BEFORE INSERT ON proposition.question FOR EACH ROW EXECUTE FUNCTION proposition.proposition_question();
 J   DROP TRIGGER trigger_proposition_question_insert ON proposition.question;
       proposition          postgres    false    216    205            �
           2620    37234 2   question trigger_proposition_question_update_after    TRIGGER     �   CREATE TRIGGER trigger_proposition_question_update_after AFTER UPDATE ON proposition.question FOR EACH ROW EXECUTE FUNCTION proposition.proposition_question();
 P   DROP TRIGGER trigger_proposition_question_update_after ON proposition.question;
       proposition          postgres    false    205    216            �
           2620    37235 3   question trigger_proposition_question_update_before    TRIGGER     �   CREATE TRIGGER trigger_proposition_question_update_before BEFORE UPDATE ON proposition.question FOR EACH ROW EXECUTE FUNCTION proposition.proposition_question();
 Q   DROP TRIGGER trigger_proposition_question_update_before ON proposition.question;
       proposition          postgres    false    216    205            �
           2620    37236 *   reponse trigger_proposition_reponse_insert    TRIGGER     �   CREATE TRIGGER trigger_proposition_reponse_insert BEFORE INSERT ON proposition.reponse FOR EACH ROW EXECUTE FUNCTION proposition.proposition_reponse();
 H   DROP TRIGGER trigger_proposition_reponse_insert ON proposition.reponse;
       proposition          postgres    false    207    236            �
           2620    37237 0   reponse trigger_proposition_reponse_update_after    TRIGGER     �   CREATE TRIGGER trigger_proposition_reponse_update_after AFTER UPDATE ON proposition.reponse FOR EACH ROW EXECUTE FUNCTION proposition.proposition_reponse();
 N   DROP TRIGGER trigger_proposition_reponse_update_after ON proposition.reponse;
       proposition          postgres    false    236    207            �
           2620    37238 1   reponse trigger_proposition_reponse_update_before    TRIGGER     �   CREATE TRIGGER trigger_proposition_reponse_update_before BEFORE UPDATE ON proposition.reponse FOR EACH ROW EXECUTE FUNCTION proposition.proposition_reponse();
 O   DROP TRIGGER trigger_proposition_reponse_update_before ON proposition.reponse;
       proposition          postgres    false    207    236            �
           2620    37239 4   traitement_reponse trigger_traitement_reponse_insert    TRIGGER     �   CREATE TRIGGER trigger_traitement_reponse_insert BEFORE INSERT ON proposition.traitement_reponse FOR EACH ROW EXECUTE FUNCTION proposition.traitement_reponse();
 R   DROP TRIGGER trigger_traitement_reponse_insert ON proposition.traitement_reponse;
       proposition          postgres    false    233    208            �
           2620    37240 4   traitement_reponse trigger_traitement_reponse_update    TRIGGER     �   CREATE TRIGGER trigger_traitement_reponse_update AFTER UPDATE ON proposition.traitement_reponse FOR EACH ROW EXECUTE FUNCTION proposition.traitement_reponse();
 R   DROP TRIGGER trigger_traitement_reponse_update ON proposition.traitement_reponse;
       proposition          postgres    false    208    233            �
           2620    37242    oeuvre trigger_oeuvre_1    TRIGGER     �   CREATE CONSTRAINT TRIGGER trigger_oeuvre_1 AFTER INSERT ON public.oeuvre NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.insert_reponse_from_oeuvre();
 0   DROP TRIGGER trigger_oeuvre_1 ON public.oeuvre;
       public          postgres    false    210    229            �
           2620    37243    oeuvre trigger_oeuvre_2    TRIGGER     �   CREATE TRIGGER trigger_oeuvre_2 AFTER INSERT ON public.oeuvre FOR EACH ROW EXECUTE FUNCTION public.insert_update_traitement_reponse_oeuvre();
 0   DROP TRIGGER trigger_oeuvre_2 ON public.oeuvre;
       public          postgres    false    210    234            �
           2620    37245    question trigger_question_1    TRIGGER     �   CREATE CONSTRAINT TRIGGER trigger_question_1 AFTER INSERT ON public.question NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE FUNCTION public.insert_reponse_from_question();
 4   DROP TRIGGER trigger_question_1 ON public.question;
       public          postgres    false    212    230            �
           2620    37246    question trigger_question_2    TRIGGER     �   CREATE TRIGGER trigger_question_2 AFTER INSERT ON public.question FOR EACH ROW EXECUTE FUNCTION public.insert_update_traitement_reponse_question();
 4   DROP TRIGGER trigger_question_2 ON public.question;
       public          postgres    false    212    232            �
           2606    37247    reponse fk_id_oeuvre    FK CONSTRAINT     �   ALTER TABLE ONLY proposition.reponse
    ADD CONSTRAINT fk_id_oeuvre FOREIGN KEY (id_oeuvre) REFERENCES public.oeuvre(id) ON DELETE CASCADE;
 C   ALTER TABLE ONLY proposition.reponse DROP CONSTRAINT fk_id_oeuvre;
       proposition          postgres    false    210    2767    207            �
           2606    37252    traitement_reponse fk_id_oeuvre    FK CONSTRAINT     �   ALTER TABLE ONLY proposition.traitement_reponse
    ADD CONSTRAINT fk_id_oeuvre FOREIGN KEY (id_oeuvre) REFERENCES public.oeuvre(id) ON DELETE CASCADE NOT VALID;
 N   ALTER TABLE ONLY proposition.traitement_reponse DROP CONSTRAINT fk_id_oeuvre;
       proposition          postgres    false    2767    210    208            �
           2606    37257 (   traitement_reponse fk_id_oeuvre_proposee    FK CONSTRAINT     �   ALTER TABLE ONLY proposition.traitement_reponse
    ADD CONSTRAINT fk_id_oeuvre_proposee FOREIGN KEY (id_oeuvre_p) REFERENCES proposition.oeuvre(id) ON DELETE CASCADE NOT VALID;
 W   ALTER TABLE ONLY proposition.traitement_reponse DROP CONSTRAINT fk_id_oeuvre_proposee;
       proposition          postgres    false    2755    203    208            �
           2606    37262 !   traitement_reponse fk_id_question    FK CONSTRAINT     �   ALTER TABLE ONLY proposition.traitement_reponse
    ADD CONSTRAINT fk_id_question FOREIGN KEY (id_question) REFERENCES public.question(id) ON DELETE CASCADE NOT VALID;
 P   ALTER TABLE ONLY proposition.traitement_reponse DROP CONSTRAINT fk_id_question;
       proposition          postgres    false    208    2771    212            �
           2606    37267    reponse fk_id_question    FK CONSTRAINT     �   ALTER TABLE ONLY proposition.reponse
    ADD CONSTRAINT fk_id_question FOREIGN KEY (id_question) REFERENCES public.question(id) ON DELETE CASCADE NOT VALID;
 E   ALTER TABLE ONLY proposition.reponse DROP CONSTRAINT fk_id_question;
       proposition          postgres    false    2771    207    212            �
           2606    37272 *   traitement_reponse fk_id_question_proposee    FK CONSTRAINT     �   ALTER TABLE ONLY proposition.traitement_reponse
    ADD CONSTRAINT fk_id_question_proposee FOREIGN KEY (id_question_p) REFERENCES proposition.question(id) ON DELETE CASCADE NOT VALID;
 Y   ALTER TABLE ONLY proposition.traitement_reponse DROP CONSTRAINT fk_id_question_proposee;
       proposition          postgres    false    208    205    2759            �
           2606    37277     reponse fk_question_film_serie_1    FK CONSTRAINT     �   ALTER TABLE ONLY public.reponse
    ADD CONSTRAINT fk_question_film_serie_1 FOREIGN KEY (id_oeuvre) REFERENCES public.oeuvre(id) ON DELETE CASCADE;
 J   ALTER TABLE ONLY public.reponse DROP CONSTRAINT fk_question_film_serie_1;
       public          postgres    false    214    2767    210            �
           2606    37282    reponse fk_question_question_0    FK CONSTRAINT     �   ALTER TABLE ONLY public.reponse
    ADD CONSTRAINT fk_question_question_0 FOREIGN KEY (id_question) REFERENCES public.question(id) ON DELETE CASCADE;
 H   ALTER TABLE ONLY public.reponse DROP CONSTRAINT fk_question_question_0;
       public          postgres    false    212    214    2771            m      x������ � �      o      x������ � �      q      x������ � �      r      x������ � �      t   �  x�UV�r�6<���ߏ����˫H��J�^ 
���-��s�o�����4���\v3�==(2�y<k�E#������� eEN׆�]+��ݝ]X+�w��e��M��%�YQ�̜�^i;������v9D�Y�bܼ��C� `eD3�XQ�v��i��ݰ�2��ZT;>S�h3\�2���i�L{��,s�t�3b/�[˲deA�F�]}l��j�����\I[�/Ն_�f��6t9��&F�f��,��A?�[>C>��� )��Ƈ=P�XcK3ӵ�k1D��&=~s���������AJ�Zz�X��Z�@\X�F�z��.՜��mՁO��Ǚ47��#�S����`KI�����娐��g�s���t�@
�M���{eE�ʴ/l���V7��4�.E��kKs�|�Ic�d�ҝ�̀V�=-�����O�cW+� ��@�>��FX��&��\4k>�V!�i�;>���H� F�w���)s��`��C�y�G,����i!�+=���f
������U=d_f�WR4���O�vB�A\Pȴ�F�i�U�X���U��N���%����9c Y��ky��]}�UY�Q�n髟c�>����k4z�x-��� �@;����8.k�� �=H�Wλ�C�+�W����E��VТk�N��EtQW���g2���K�6�U%�F�����e!���uǍV�=1���b�|�v��;dQJ�g#���U�%�������E9]��j|&̓�>B�-�0���}=QI7��vb���.���G�|Ö��P?���S����͕s���Jq�g�;��8��7Oǈ��ó��f;2�8���ȝ�L촀���'c�����鏍kl>��xv��
�b#�J��4.�D��T]{Gr��,��t��h�%!-ju���%N)b��d�Ib�����K�8#X����t�+=Z����-��\���L5j?8�e,�	��F#��_�ɞ����@��|ʓ�+����+��&,Pd����4�~��j(��}�Y��y��lp�w^ס�k3�Ɗ�)]bB�x3T[��/�j{f�Wb��7;��m~�^G�.����ߕ��HY��/u���,�ۚ?���Vt��|�뵰|q�K�퟽Uw��I��k!��m�^m��;d<#��n���
X��qȲ�~�Μ�V���`ڂ˦�N�Ba�tH������zye9]���jԋ�§��V�m������p�˚QdE����Ǒ����3e&��o��q��P�V��:���,9�C��G8c"E���q��/��� &����s���X�����N���Yw�ޡ�{s�3�K�C��
�2��rBW�GV�,/o�Q�(� ��ʾԊ ��Zx����"��w_D�t�<X�T쁶~D����"��j7� O�t�'\�	��k��82��猱5� �      v   �  x��W;rG��SL�Dp��R�r$+��*W9���wg��EGN}g
'>���'���@qd�X$w�{z���~;��a�+��99���8�|jU<:%��̃���������:���/�������F�'��t�����*KQ�~�6^H����a�ND�mtB�;i�l�!e,�d][�<�\��h�Q9/�Kj�}P�퍺G�m��;�/w����6�oT�+�{�ͳ�;÷�q�5F��o�M�k�sr�l-l<Z�l|tF��TI7�/�ARm�0�>Ċ*�8���r����� I�{�d$7����c�Dd
ˡGʈZ����o�49�t���	�R�W�ٚ7�p���?�~��h���y羬h�i���b�B��FWT`״�h��� �($�F���l�� �;u�V������U�����@�;�*:4e���˹�����(ɲ��g� ����#���&=�l�?�)�B���2Q�9��o��`���N�_�	F�x!�	�^�aZ��/�dZpEQ��k�AC�a/  }3d~���H�A/��R��/7Z��"lGo�<�������g;0��r� �1�v��I(x�x1;'Yȋ�N��C5��Ls��l6����]�
0@��O���U��/���3͉F3�b��\:�OR���Y�8�2E##��b��@s� zШB���Sݟ�I���v��>�6)��i=W�M��a�l���r���Bx?O��Ө�c�\|��T �
��˒�J��/Suf����ˋ}����5�[f�Џ�h��>��l��q����쾻�}C�ٵ�kv��	t:bP����n�6����uˀd��{��G��3h��heH���������u���Ά����� ��E�ڊ�U
�5$�T�s}_���ڎ����OHK,/5�VT+�:�Fλg83�������S�t�0�ږ���#S�:��:�coqdA*m*���s��`���/q_�Pl�J������D����*���I7���i���|"��ě���@�Y�)��gcc��&�����cɕ@~��)�����
�n�� 9�[���D�A�Q��@���mGh[�*P�G+���Y���V8k��i�ڮ�93�<A��G�)L��+0� ]��3I�gHn�K��gPL��Z���~l�O���,��+��E)�ؕz`���*�#��YA����	iAO��Y��䚿��Z�t��!����Ty�ꮟ��N����(uY^�B�+�7� �u;�:�����(�/��٥�9/0��O*��v�V����Xt�ä �B��/��餿�%I�Q���x,˲�Ⱥb��"N�J�r�ZDY^�QS�f�����:���f��t��v��棷���р�=)��쿗�w�{����0ޭF/u��4Dj��G/�	�H���NŖ� ċ�dj7�-7㟾���r�       x      x�t�M��H�&ڱz5���M�
������:IU�R�sM37f&�]��������^��������Y�γ��R=K��T��Y���zl�W��_�@-�ϣV�=�n����\�W񱒯�^�b��Ϸ�����w�I_��������U�?�W���xϾj�e���������H�j���Å~~\���o���]|����|b��c���ǻ�.>Vt��~��� ����.>W��������W16��w�w񱢯�y=~�y�Y_�Ǟ�U{,'�g}����=>���s)�l_��B�"��R|l�����w��}�»���w��9�K񱢯�sg{�ͻ�\�`g{���`g{л؏z����ώ~��U<w��ϝ���l��W�u���_����}�l_;��<j���]|4�w�񆿋�m|o���x����f^��Տ_��sg{˜x�W��,>��.>�>��c;��Ǉ�.>��]|�W_?;_g������^����}�ֿG-����o�?�x?����������p}����{���z��_��>�U{��7���W���~�o�W�����ϭI����sSGR�~�S}����σ�w�y`�J���σ�w�y���>Zϧ����\�b_���߻��}U������&�X�W+��b�_U|B_U�-�S�ڂk�-���ڒkK�-���ڒ�[rmɵ%�V\[qmŵ�V\[=�=�U�����ڊkk�����ښkk����5��\[�ޝ�چk�m����湶g�^8�B�^h�K=WW�G<�qϐq ��Mq��p��p��އ�?�p�s����:�~�����!o�=??���X7>V�#�Yg�:A��Xuz��㍏z���ov�rc��:�y��>)Y?^���>�z<�ྪ?�{��m���ί�����_��؅Rō=|�,_'�:����?��gf���q~�������s�?Ͻ�<������s��)���u���]g�:y?ʄ	)R ���(R���`7�ٹN�v��b �@���@�	 �?�M���|��i��Dg�:׹x`7	�&��$���['܁�$�*2Tb��N>w�|�&��M��M��s7�9-NiqF�Z���t6�*T��O��2?E~J���$v��&v��n��M�I���>�|����!�{�&�kO���A>���;���*w��KB�"T�\�}������D?���� ��A��Q#j}~_[A+������J����VF��D�t=H����.�Z�.5v��n��M��<w�y�&��Mp	W�p�p�Wt�g�v��n2h��Ds>�r?��Mt%GrFy��v�&��d��+j�n2�M�s7��\���\�����h#�F��8[i��le��&��+.�Da.v]�����Π��\�*���nr��\��pc�����u���_5w��^�^J�^��|]��%xU�%xM��$xEBQ�Kl�`�dL�g=�������Y
/�^2�d~� s�/�����c@���S|/�������g�\��|��Z����r�F������"�\H=bϵ�B�}.d���R����S�� t)]�@�2Хt)]�A�rХ t)	]���õ�6���%"�D�ąq!C\Rąq!G\�ĥ(q)K\
���u��B
�ťHq)S\
��kŊ� *X\J��ťlq	�|-��G�E��
.����R��r�����n){[
ߖR��Xm!C[	��m!F[�����$m!J[�Җ´�4m)N[�!�:$�}R��'_K��"� Q���-�EkK��R��������{¾���'% ��p�g��w~~E��.��.���=�����m$��?ޏë��
]��f����4�����R��w��m~ź��7$��_��K~��h�/Z鋦�t)3]�������H"ǅ�q!t\Hb�%���q)y\���å q}O���-S��Z��+\J�����n!�[H�⺅�n)�[��W��Rf�F{��%n���-rK��R����-pK	�R�.�
��-dia�B���-�iK��R���-ejK��R���-ehK!�R:��-�cK�RB����������,m#K���6���,m#K��Ҷ���,m�pb���mei�%�Ā���(���w�?��㠧�}����A����<^�P���%��_-PC ��L�⏷w}���`��ק��-�Y��Ǐ��ο��~u��ɩn��}8���� ��I�Sk�.��L��~�f�����ne�[��~f����_ �A�A�A�A�A�A�AB
Bs�MDHEHFHG��lo9�F�����m�g��>���7ⳍ�l#>ۈ�6ⳍ�l#>ۊ϶Ⳮ�l+>ۊ϶8�V|��m�g[��>��ӣ�a�ۊ϶Ⳮ�l+>۲yI�����m#Q�H�6��o�z�5��ַ��-F���R��@n��my���n��3Dw�m#�ۈ�6����n#����q��Ft�SbBLlEw[�ݖ�ۊ��'�CQۉ�[��N}�u��Vt��mEw[��Vt��mɸ��ˍ�m+)��]~��ǡ׎�oǷW>���V�]�ۀxQ�.예�vi�,혊������k+��J��(�V��K��4���[�os�2�]���:�]�V�m�o��3�����+ۊ�� �V�E䶌�V���m�`����m�����6¶��m#l��6¶=�N)l�
۶¶��m��m%p[	�V����苦�[Y�VV���meu[Y�VV���6º}�={�is��V0��ms[��V0��ms[�m+��W��Һ��n+��
涂���� ;�b�#Bv�p�Y�)�w����=�Z��ÀD����?�[���=���׵�?��_9�{�G�������\�~,�<���/|P�����������S�o�[m��=V������V�s�ouA@������O
�s���^ʝ�r��w`��߁�;�}������#�wt���-�G�#��{�t��$<�xg�^<�#�wd��ށ�;0z�&����C����|,n��۸(|�蝍���%zG ��%zG��Q�w���R�{juS�y^�9���<���kug�n�彵���w���Z%zG ��[�b�{ly�-�U�wx�-o�坶�Ֆ���f[���D���H��=H�R����(�;
��=�}�(�;J��R����zF`8�Qx��Gy�Qx�P��<�$:���nu��~��矯����R���mߊ����W������a�����D�o���L���y^�<��?��;����]���t�W|��??�D�E
{ (R�#@y(�Rأ�Pݒ|(�Rأ�(�=Ja�Rأ�(�=Ja�Rأ�(�=Ja�_��ַC�2���_G�y$���̣8�(�<�3��̣8�(�<�#��ȣ<�(�<���4�#���h���i�k
x`,��<��G�p��nD>��(C=�P��Σ��(�<�;��3���w���5����΃�� �<Gy�Q�y�w�G��Q�ymE�G��(�<�6��ͣh�(�<�6���3�[p/��W<�@n>{f����VD�Q�QTz�E��j���Y��Q*z��ƣ;��n>�&o�G�A��T��c�?�L�p=�<��������N��G���<���"��HX�3�f���z�j�#����z���z���z�j��x�JP(���!�J��/@(���!�B~��g��!��!�P�
[Cak��-�B��O��$���6pwv ����@HociZ�@JoC�m(�M�E��H7�&O��.�4sk!WM�%¡D8������@L���s­ܱх6�b�@L��C1qȢ�,jȢ�,j�i!���;dQC�uȢ�VRrJ�C��� ���8 B�q >�ǡ�8���P|��C 4���P|��C�q(>�ǡ�8� �P|��C�qpX��5Z��5j`c� ��f6jh��6rl#�6*{Nn����.�፜�������]�#9�Q�LNq�G�q�B���g$�?B�@��7C�f(�囡(3e���P�J-C�e(���g��2�    Z�R���(|d�,7*G�^��:ag �ݻJ@C	h(%��gy�b�P,�EC�hh�c��)�P���ZCQk(j��@��_����0h�^���؁�5����P��_C�k(�!��_C�kȰ�k�N9�t��vi����	�"�P$���p ��.�6�R�P
R��h6͆��P4R��h6�F>o�|�o��"�EB�E�o(�¡X8�b�P,���p\�1���[���m �¡X8�bᐠ	ڐ�eš�8�����eš�5����.��5�����PښH[ik���P"mM(�ĝ�	��H[ik���TښJ[Sik*mM��J[Sik*mM���[�S�T���TښJ[Sik*mM����5����.��!mM����5��&�l"mM��)+�J[Sik.ͬ_Z��5�����TښJ[s���m*mM=(����TښJ[)j�&�m�&��O���5���R�T��JQS)j*0M�)�
LS�i��Xn��&n���OO�*-�Y����rc�H>����g�>·D~��o�m"�M䷩�4����TX�
KSai*,MY�TX�
KSai��&��D0�����3x&�T��
<S�g���T���1S1f*�LŘ��2�X���T8�
'SO�A6�z�m�2z���+����2|��-Ç���2|��/���	3|��1Ç�(M>f�ϙQ,�|�5�g�s&��DV��J�I��x�L"+Md���4�����TV��]��)+Me���4�����TV��JSYi*+Me���4������crYi"+MXՄUMd�	���JYi"+Me���4���s\��6����TV��4�y�@j�E��@�oE���΀TN��iS37S9m*�M����iS9m*�M=�'��&r��M�*H�*H�*H���M���M�Ʃ�8��
�S)i�>��ɥR�TJ��P�#��_@�D"�HD�g"�L����3�~���T��J?�>��3~�rΔ�Me��L2�I���,Ċ��!"�R�X�Kb��뗂�R0X
K�`),e������R�WH�
�^�Q�������B�WH�
�^�.�R�WJ�j�?�R�WJ�J�^)�+%{�d�t�|)�+9�R�Wr�%GYJ�J�^-5_8ʂ�,$���"d�8����+�
�2ߊ��y1d#/����ܢz�޳~��yV/lf�pV/�+������B�BHZ
IK!i)$-����-5-%���DMK�i)9-I(Q�5-Q�R[JcKiliHB!�-D�����\)i!%-���������kI���kI���kiHBI�����Rp[
nK�m�Y�������B�Z0�����"�R�Z�XKk��gU�Z2��0�Ɩ��R[
cK��4���ЖLiNkJ�m)�-��B�[�rYn!�-d��,�����B�[�rKYn%fڗ��R�[�rKYn)�-e��,��喲�R�[�i٥,��喲�R�[|p���,���p=<\O�����pd��,��喲�R�[�rKYn)�->��9����s>�\Yn�a�|�9w����|��k!�-d��,�����B�[�rYn!˭�(e��,��^K喲�R�[�SKyj)O-婥<�����k)O-婥<��^yj!O-䩅Q�<�0
�����B�Z�SKyj)O�QR�Z�SK��pK��pK�J�F�B�xKo	"�R�[��[�_K�k)~���ů��U�������>-���P���9�OK���OKAo)�-�§����J�o�6�F"�J[�o+�m�V��J[�o+�m���������Iڿ�z���c+n	�F���zYo���G��o�{��?~��������g�����Vx�
�[,�	�"�V$܊�[�p+�m�V��
z[Ao�p6B�F��H'�d#�l���$��D���V�⚭б:�B�V��
[Qb+Jl=��%���~Bʯ"��F؈q`#lz�@�赲��lew�쮥&[����dH��&���8�H��_#�k$����䯑��"�V�֊�Z�Z�GZ�Z+RkEj-	ي�Z�Z+R��g�H��5"�F�ֈ��Z#R�����[�Z+Rk��ֽ�{�[OjEj�H���"�V�֊�:�-�Ǿ=Fo�?WuR��n�����ޟ����(��W�z��@-��
[a`+��{3�G�g �>-�IGg]��S|�2��\�x���g$ҟ��+�d���.|s�d6�����$��d6��F�مo���V��J2[w��V��J2[If+�l%��$����V��J2���+�l%��$��d6R�Fjٸ[��Z6��o���Բ��R�Vj�J-[�e+�l����P��֍��ر�8[�c+vlŎ�ر16"��lD��وc>oE����1��f�>�V��J[ib+Ml����[a+#le�����6�g�w6nxo���ld��̱�9��g+sley�,�5���嵲�V����Y� �dy�,o�������{�|o������z>����y����q�������S��O�ϯ|�F=�Gǟ�ֿ���������a�(���(�����sv���Q�9
;Ga�(����[�a� ����r�C�r�Q9�!G�@G�@G��(�%���rt{��N�Q�9�1G1�(�Ř�s��Db�x�A�9𪃸sw��A�9���qd8�@G�(E�#�9�EG��(墣'V��~�0�(A%�#�9JPG	�(A �A�:HP	� A9�Q�:�U��4q��b�Q�:�UG$r�����Q�:�C}���A ;`� ��� v�؉���^���^��y��yN����c�'���r�QN<ʉG�� l�ߣd���~����~���!�{?��<���qyd�k�簱9�&�9��������"�A�<���(N�ɣ8y'���(9%ǣ�x���㑻��Q�:�ZGQ�(�����r�V��AZ9H+i� ���w9J+Gi�(����y�SjAJ+Gi�(�����r�.Gi�(�����r�V���QZ9H+i� �$��dr�L<����Q29J&G��(��ŕ��rW��ʑ�ŕ��r�L���Q29H�w$���q�8��]?JG��(]�� q$���Q�8:JG��(]���tq�.����ų�~Wğ�3�D��hrM��A49�&G����
��q�ӿI���+Q{�9q��cA�y��[���}k,�����lt쨌v�ю\�ȅ�\舀���(���0x���Q|��^�W��U&{��^e�W��*q�J��C���B����v�-^e�W��U�x)/rċ�"G��A�*[����ūl�*[����ū�*F�J�ë��*1�J�ë��"1�����Ebx�^$���Ebx�^�ɫ��*1�J�û�(1�J�ë��JR^ݾ}�^%�W��Ubx�^%�W��ŭ�)�ͼH/�ŋd�"Y��U��V���*��� �d�խ�W��U.y�K^�W���]�Wa�UXyV^��a�}�'�>�����q\r_�C��¡�}^�[�����GK�.��%������>M��ݿ.,����۸�*���}/�܋��"���n/�۫��*���i�rګ߯��U�z�^1�+f{�l�����Jt/H�Eʻ��յ��𹑢�W�U�x0^�WB�*6���bë��"�H/R����"�H��R����*�J��R����*廅W)�U�wF�*����n�����*����.b��H�"����."��H�*����"��H�*����ҷ���
^ݸ|�]ErW��*����.�����1�ELw�]�{|������*�����=V�ġK��&ק�=���t�o?�t�71U붊�jR��6�����l����<�>��G
u��������;�3��y\�^����������K���#뺁���Y�>C=>�*������8��.��8�*������8�*���x�EB|�󦡋��"��~/�ߋ��*��
~��Ϋ��*��;��Ϋ��BЫ�௒ѫ�0]ťWq�U\z�^ť�q���zϾ����]|l��ؤw�I��c������r���d7?��;��rk�������ו��^�y��"�-    ��"6
�껈�P�꧊�P���m}~�>Un����>�B�*>F�V��r{�ߘO�۫�\�맊U d}���Y�E� A뻈�G��.b��~6���Cy��m�Ρ��S��j�Q���b�Q���>��O�kӎ���S�'�I��g��ڎv/L�x�D�W��|`� ^�i�?o��tD���}^��z^�Z�����x��^�GZ�.��F^�.��Fb�.�Ff��L����)��T����)��T����)��T�S|��rm��)��T�6}�l�\�sh�zA⾋X��w�B��.bU�t�E�	�P?���S�j����T��ڽ�ؽ��\�3_�T�6�^��?U�M��R���4�w+C��.b]��"Vp�.bM���xn�v/I�O�۪�K�������S�_��p�S�_�Ӑ�����;���"�D��"�a����T���r��)*Q�T������^}���?U�M��(o�T�
���?U�B����Ͽ��xp����e!��(���"��<�S�jGR����#�7�X~~����O�+�.���*�����I>U~d�u��S�ڴ#�vD\`x�0��w��w�¥�wK�ŇO�[�Q�>Un�v/˟*�W����O�k��!��*צ�K��ʵi�D^/���"V�D�]ĺ�I��XR�wk����>���h�S�j�R:��rs���?�+?�^��?U�M��*��T�6�^
�?U�^���ǥٯ�3��u����<���yn�����_�ݿ�s��9��Ưx~���I�
�#����7���:��#���:�H�#���:�Gb��%�����������6���ͥ��\���{_x��}�o�����67���͍���ͣm��^��uX��;=X�<>���<~�~��g��#6z�F���=b�Gl���#6z�F�����#��m�=b�Gl���#6z�F���=b�Gl���=���:
�x������76��F���}c�ol􍍾��76��~�5���K6z�~��g�x������}�Y�:�}����<j�>t�}����Cԃ�q�7��A�8�}�o􍃾q�7�-��A�8�}�o�������}�o􍃾q�}�Y�:�}�o􍃾q�}��g�8�}�o􍃾q�7��A�8�}�o􍃾q�7��A�8�}�o�F�x#�7��������������������aϾ������@��@��@��@��x���~����8��@��x���`Ͼ����������������������8OI�D�H�D�H�D�H�D�H�D�H�D�H��yJ�o$�F�o$�F�o$�F�o$�F�o$�F�o$�F�o$��D��8��w�x��x��D�H�D�Ho$�F�o$�F�o$�F�o$�F�o$�F�o$�F�o$�F�o$�F�o�F�o�F�o�F�o�F�o�F�o�F�o�F�o�7
}��7
}��7
}��7
}��7
}��7
}��7
}�p�Q�����F�o�F�o�F�o�7
}��7
}��7
}��7
}��7
}��7
}��7
}��7
}��7}��7}��o4�F�o4�F�o4�F�o4�F�o4�F�o4�F�o4�F����}y��F�h�F�h�F�h�F�h�F.�8�h��4�7}��7}��7}��7�����������������������������������1���1���1���1���1���1���1���1���18��A��A.:���1���1���A��A��A��A��A�o�Ơo�Ơo�Ơo�Ơo�Ơo�Ơo�Ơo�Ơo\􍋾q�7.�S.��E߸�}�o\􍋾q�7.��E߸�7.��E߸�}�o\�㍋�q�7.��E߸�}��<��<�o\􍋾q�7.��E߸��}�o\􍋾q�7.��E߸�}�o\􍋾q�7.��E߸�����%����z�t�d�^\/	�׻-<��K��%���z�q���EX:Q��,�K��%���z�s��^]/���L���]Ԋ���V����z�{��^_/��5�E����A}�ľ^r_�����?�ǀ���k�0b/!�:ʻ�e���^�*ɾ��d�ߵS���҅�R���҆�R���҇�.5QQ"Q*Q2Q:QBQJQRQZQbѥƲ�X��Rc�"%#�#%$�$%%]j,Ĥ������������t�]P���Ґ.�*R1�%G�I���%]��K�tI�.q�%O�J�D�)]2�K�tm5���"W�6�%Y�DK�l�.]ҥK�tɗ.�%a��˖C2]Wa���3]��K�t��.Y�%l��M���7]�K�t��.��%t��N���;]��K�t��.��%|��O�����~����<�;:�9�K��KXuI�.q�%���Τ$V���Y]B�Kju�%��%��>r����K���/I�.��%��X��a]2�K�uI�.1�%Ǻ���$�e]��K�uI���3)y�%к$Z�H�i]B�K�u��.��%غ$[�h�m]ĭ�[z��mDT���H]�K$uɤ.��%���R���8]�K�tɜ.��%u��N���<]��K�tə��W[�t��.Y�%X�$K��]B�Kjt��.��%8�$G���]£Kzt��.��%@�R��c�ԑ��"]b�K�t	�.I�%J�dI�0�&]��?s�~�94�f�)�|?ק�<�������c��z*���������������a�4��]�+u#�Db�L��]R�K,v��.��%�R�.��cW�׉�.��% �$d��쒑]B�KJv��.9�%(������V�V),��e��쒗]�Kbv��.��Uj���X +KFv	�.)�%&��d��쒔]��KVv	�.i�%.��e��q<����^�l,"�Kfv	�.��%6��f��쒜]��Kvv�K����.��U��oI�.�%C�J�E�v��.9�%H�$i�(풥]´K�v��.y�%P�$j�H풩]B���XZ�E^v	�.��%2�>f�����H�.��%7�g����]��KxvI�.��%?�h���]2�K�v�#���Wj�h,��"]��k�|��]�K�v��.!�%e��lW+x�]��K�v��.a�%m��m����]�K�v��.��%u��"a��M�خ���&K�.��%S��j�T��]r�K�vI�.��%[��kר���.��%`�F��Cl��E�vIٮ����g�"i�Dm����]ҶK�v��.��5�!"�K�v	ݮ��}�u��=D�vI�.��%{��o����]�K wI஫,�����G�v}�-^�|C>��|�!b�K�v	�.��%z����풴]��K�v	�.i�%n��m��풸]"��j>�Յi��%b�dl��풲]b�K�v	ڮ�BY?��+���oE}��6��KVw	�.��%��ds�p��]�K>w	�.	�%��_���Ґ��X�Kc�w���~iҚ4���/[���Ҽ[�wK�ni�-ͻ�y�4���Ҽ[�wK�ni��Ѽ?G�I�ni�-ͻ�y�4���/ؘ-ͻ�y�4���Ҽ[�wK�ni���(6i�-ͻ�y�E���w����݂�[pw�n��-��w7':r�#g:r�#�:r��������Ɏ��َ����(��%�6'<r��F��9�S9�s9葓9ꑳ%�6�=r�#�=r�#'>r�#g>r�#�>r�#�>r�#'?r�#g?r�#�?r�#�?r $'@r$g@r$�@J�mI�-����FAn��}p&������Ԗ�����|ݖ���u�h��|ݖ���u[�!�|ݖ���u[�n��m��-_�����hكӫ-_���|ݖ���u[�n��m��-_����En��-_���|ݖ���u[�n��m��-_�?���i����m��U����J��ܡ�"��%��E�Pc���y[<o��m�-��C�Es#� ��ۂ|[�o�mA�-ȷ�� ��@��2�X4CrK�m�-ݷ���t�\��%�E����59��~���p��[8pn��-���p�܁�[8pn�����    [&w��$�4m��-���_�rןW>�:��-1�%�G>7-H�n�F��m���)�[�n�m��-t�������Bw;ul#t�������Bw[�n�m���AwύG����+ql�Awx�V���[�n�m��-t�����NۤZ����ۚT�5�r�m��-t�������Bw[�n��Rc��Bw��X�Tn���Bw[�n�m��-t�������Bw[�n�m��-t��Vn��-t�������Bw[�n�m��]м[�n�m��-t�������Bw[�n�m���Y�[�,w�0FoK�mI���[�+�$ޖ�ۭ�"��%�v��H��Vc��ےx��I���+�Lt�-����xޖ�ےx[oK�mI�-��%�$ޖ�ےx[oK�mI����[oK�mI�-��%�$ޖ�ےx[oK���aL�0FoK��Q���y[30��ޖ��2{{����m��-��e���ޖ��2{[fo��mM�ܣ�O2{[fo��m���2{[fo��m��ܣ�&��2{[fo��m��-��e���ޖ��2{[fo����I���֨�-��e���ޖ��2{�c����n3�62{[fo�����̭����h"����y[<o��m�-����x��ۚ��e�����2{[fo��m��-��e���ޖ��2{[s2�e��Q�[�o�mA�-ȷ�� ��ےx[oK�mI�-��57s��m�-����x����y[<o��m�i�G��C����;BwG�����#tw�����;BwG���C����;BwG�����<Bw��GG��pr������#tw�����;BwG���C��#tw�����;BwG�����#tw�����;/����#t�u�ǡ�Y�g��K�E#4�Fh��<�y4B�h���ͣ�G#4�Fh��<�y4B�h���ͣ�G#4�Fh��<�y4B�h���ͣ�G#4�Fh��<�y4B�h���ͣ�G#4�Fh=��h���\ͣ��Gs5�������h��Σ	�G8�&pM�<��y4��h��γՂ�~�&p���$�{6$��γq�t�~����=r�G����=������#�{4������#�{�~����=r�G���!�G������#�{�~����=r�G������#�{�~����=r�G������#�{�~����^����=|�;��~�m�x>�π�C��x>�ρ���$x>
�ς����4x�������|"<	�g���>����s��`x>^�����|8<�������r��O��#������ >%����s���x>)�������x>-��������x>1���ό��=zB�	�Pp�~����=r�G������#�{�~����=r�G������#�{�~����=r�G��|��sEh,��G������#�{�~����T�#�{�~����=r�Gϑ?r�G������#�{�~����=r�G���c4����ߣ��=r�G��h(��=r�'�mD|����="�GCA����C��j�#�{D|����="�G�����#�{D|��j�#�{D|����="�G������<"�Gs5����\�#�{D|����="�G�����#�{D|��j�#�{D|����=��Gp����#�{w��e��SJ�y�Fh��e�&څ���=��Gp����#�{wO鬧�[�5w����=��Gp�������w���=��Gr�H��ݣq�Gr�H���#�{$w���)���#�{$w�B$w����s�kq�#�{ZG'�G����qޣ��G����N4X��q�#�{�y����=��Gr�H���#�{$w����=��Gr�H���#�{$w����=��Gr�H���#�{$w����=��Gr�H�}���6��y$w���ѣ돞]$w���������=��y$w����=��Gr�H�Q���=��Gr�h���=��Gr�H���#�{$w���Ѵͣi�Gr�H���#�{$w����=��Gr�H��ݣi�Gϸ?��Gr�H�}��6��G�6���Ѵ�3�t%w��m��#�{4m�h���=�G��?�G����q�#�{�y��t�y�8���#�{�y�8��=�G����q�#�{�y�8��=�G����q�#�{�y�8��=�G����q�#�{�y�8��=�G����q�#�{�y�8��M�ߐ��Mh�f���o�p���!���!���!�����=�!�����!���!���!����i�!�����!���!���!���!���!���!���!���!���!���!���!�/�4��m��o��R����n#K�F8��C8��C8��C8�i����n#��!��!��!��!��!�p,$�!��!��!��!����m��C8��C8��C8d|C�7d|C�7d|C�7d|C�7d|C�7d|C�7d|C�7d|C�}C�7d|C�7d|C�7d|C�7d|C�}c������o����o����o����o����o���f��V���ߐ�ߐ�ߐ�ߐ�ߐ�ߐ�ߐ�ߐ�ߐ�ߐ�ߐ�ߐ�cߐ�ߐ�ߐ�ߐ�ߐ�ߐ���lߐ�ߐ�ߐ�ߐ�ߐ�ߐ��8�62�!�2�!�2�!�2�!�2��پ!�2�!�2�!�2�!�2�!�2�!�2��پ�پ!�2��6�����xnA���o�F��h�o���o���o���	ٿ��c��������������������б��o���o���o���o���o�m��o���o���o���o���o���o���o���o���o���o����o����o����o����o������8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8o��8ohbo�z����4pH�4p��4pH�4pH�4pHG��H�7Cc|C8��C8��C8��C8��C84�74�74�7��C8��C8��C8��Cc|C8��C8��C8��C8��C8��C8��Cc|� fB8��C8��C8Z�G��!�纅f��0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0p�0ph�o����0p����0pǨ��0p�0p�0p�0p�0ph�o��a�a�a�a�a�a�a�a�a�a�a�a�a�a�a���a�a���a�a�w��.I�U��	�	�	�	�	���߸�6�!!�!!�!!�!!�!!�!!�!!�!!�q񰷐	�	�	�	�	�	�	�	��6W�FB8$�SB8_�6)!�/t��N	�N�N	�N	�N	�N	�N	�N	�N	�N	�N	�N	�N	�N	�N	�|�ۤ�pJ��pJ��pJ��pJ��pJ��pJ��p~���]zv��N�N	�N	��h��N	�\�6�)!��)!��)!��)!����)!����)!��)!��)!��)!��RB8%�S�S�SB8%�SB8%�SB8%�SB8%�S�SB8%�SB8%�SB8%�SB8%�SB8%�SB8%�SB8%�SB8%�SB8������Na���s��lL�Ka�Na���Ҋ�X��S8��S8��S8��S8��S87&������0�Na�έ�a�Na��j,��)���)���)���)���)���)�[�E8��S8��S8����0F8��S8.v�0p
�0p
�0p
���0p
�0p
�0p
�0p
�0p
���TR    8��S8��S8��S8��S8��S85�7��S8����)���)���)���)������)���)���0f�,����O����o����o����o����o����o����oj�o����o�����>�O4�ߔ�M�ߔ�M�ߔ�M����ߔ�M�ߔ�M�ߔ�M�ߔ�M�ߔ�M�M�ߔ�M�ߔ�M�ߔ�M�ߔ�M�ߔ�M��5�ߔ�M�ߔ���a��o�c��S8��3�mR'M��)���)���������)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��)!��6�)!��)!��)!��n#!��)!����n#!��)!��)!���)!��YxvJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pj\pJ��pJ��pJ��pJ��pj\pJ��pJ��pJ��pJg��H��pJ��p�Τ$�SB8%�SB8%�SB8%�SB8%��K��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��pJ��p������pJ��pJ��J��pJ��pJ��p��m$�SB8%�SB8%�SB85.8%�SB8%�s�m$�SB8%�SB8%�SB8%�SB8%�s�m$�SB8%�SB8%�SB8%�SB8%�SB8%�SB8%�SB8%�SB8%�SB8%�SB85.8G�FB8%�SB8��0p
�0p
�0p^5a�Na�Na�N�Na��``l��#Na�Na�Na�Na�Na�j,��)����q�)���)���)��\�0p
�0p
�0p
�0p
�0pj\pj\p
�0p��CJ���yK���yK���yK��>�����vQҼ%�[Ҽ%�[Ҽ%�[Ҽ%�[Ҽ%�[Ҽ%�[Ҽ%�[Ҽ%�[Ҽ%�[Ҽ%�[��[Ҽ%�[Ҽ%�[Ҽ%�[/\]�����⳱��o����o����o���&��o����o����o���&���Q-� �ߒ�-�ߒ�-��Z8�)�ߒ�-�ߒ�-�ߒ�-�ߒ���Ø��-�ߒ�-�ߒ�-���d���-�ߒ�-�ߒ�-�ߒ�-�ߒ�-�ߒ�-���d���-�ߒ�-�ߒ�-�ߒ�-�ߒ�-�ߒ�-�ߒ�-�ߒ�-�ߒ�-�ߒ���n#\�����%\�\��%\��%\�\��%\��%\��%\��%\��%\��%\�\�\�����%\��%\�\��%\��%\��%\��%\��%\��%\��%\��%\��%\��%\G�F����0p	�0p	�&�0p	�0p	�0p	�0p	�0p	�0p	�0p	�0p	�0pi2p	�0p	�0p	�0p	�0p	�0p	�0p	�0pi2p	�0p}0����0p	�0p	�0p	�0p	�&�&W��h2pI��pI��pI��pI��pI��p�^I��pI��pi2pI��pI��pI��pI��pI��pI��pI��pI��pI��pI��pI��pI��pI��p}��s�D��.	�.	�.	�.	�Ju	�.	�.	�Ҹ��.	�.	�.��T�,!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�U�6�%!\�%!\¥�%!\�%!\�%!\�U�6�%!\�!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�{-KB�$�KB�$�KB�$�KB�$�KB�$�K3�KB�$�KB�$�K3�KB�$�KB�$�KB�$�KB�##����.	�.	�.	�.	�.	�j��]�%!\�%!\�%!\�%!\�%!\�%!\�5�6¥�%!\�%!\�%!\�!\�%!\�%!\�%!\�!\�%!\¥�%!\�%!\�%!\�%!\�%!\�!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\�%!\��FB�$�KB�$�KB�$�KB�$�K3�K3�Kl�ĆKl�ĆKl�4C�ĆKl�ĆKl�Ć���Fl�ĆK3�Kl�ĆKl�ĆKl�ĆKl�ĆKl�ĆKl�4C�>l��~�ۈ��p���p���p��f��p���p���p���p���p���p���p��f�f��qk�pK��qK��qK��qK�f��qK��q��q��q��q��q��q��q��q��q��q��sW|6�0n�~���-`�b�-6�b�-6�b�-6�b�-6�b�-6�b�-6�b�-6�b�-6�b�-6�b�-6�b�-���-���-���-�ۚ��r�-��r�-��r�-��r�-��r�-��r�-��"�-��KM@���y[���y���ק���Ϗ/�}�׷߉�"!��-!��-!��-��r�-��r�-��r���.�څ�o����o����o����o����o����o����o����o����o����o����o����o����o����o����o����oo� ����$��"�-��"�-��"�-��"�-��"�-��"�-��"�-��"��y�-��"�-��Ҽ-�ۂ�-�ۂ�-�ۂ�-���-���-���-���-���-���-���-�ے�-yے�}�$o[򶏚��mK޶�mK޶�mٶ�mٶ�mٶ�m��_7%�{�_GX?�q[P��8n��8n��8n��8n����ށ���S���U^���3�m��m��m���\*j��m��m��m��m��m��m��m��m���P[�m��m��m��m��m��m��#�ZķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķON�T��m��m��m��m��m��m��m��m��m��m��m��m��m��m��m��m�.<��E|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|��mJ�FķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķE|[ķ[�FC�[ķE|[ķ�y[���y[���y[��5�w[p�w[p�w[p�w[p�w[p�w[�}[�}[p���w[p�w��Cw[p�w[p�w[�}[p�w[p�w[p�w[p�w[p�w�����n��nk�o��n��n��8n��8n��8nK޶�mK޶�mK޶�mK޶�mK޶�mK޶�mK޶�mK��?��N���q����=�J���m��u���m���m���m���m���m���h��1��-�ۂ�-�ۂ�-��2��Ѿ-��2�-��2�-��2�-��2�-��2�-��2�-���-���-���-���-���-���-y��-O�WM@���i[���i[���i[���i[t�Eg�귔lKɶ�lKɶ�lKɎ��HɎ��HɎ��HɎ��HɎ��HɎ��HɎ��H������)ّ�)ّ�)ّ�)ّ�)ّ�)ّ�)�����������M���������y}��c�٤�E�y��_7��)�~�=M���N�u�㐑��ۑ��ۑ��ۑ��ۑ��ۑ��ۑ������YjV2�#�;2�#�;2�#�;2�#�;2�#�;2�#�;2�#�;2�#�;����ѬdtGFw4�wwGpw4�w�yG�w�yG�w�yG�v$oG�v$oG�v$oG�v4�wNpFFwdtGFw┑�ݑ�ݑѝ��#�;��W>ߥ���<��wIFwdtGFwdtGFwdtg��������������������������������������lL]��ܝ�i�#�;��#�;��#�;���    ���M�a���������h����h�H�4�H�4�H������iޑ�iޑ�iޑ�iޑ�iޑ�iޑ�i��p�������������9:8���ߑ��ߑ��ߑ�iޑ�iޑ�iޑ�iޑ�i��h^���$y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;�;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;��#y;���:b�����֧���Ϗk�hA�#�;�#�;�#�;�#�;�#�;�#�;�#�;⸣��#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�Sx.ۈ�8��8�h�I�D�8��8��8��8��8��8��8�/;�#�;⸣��#�;���x�V�n#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;�#�;⸣��#�;2�#�;2�#�;2����#�;2�#�;2�#�;2�#�;2�#�;2�#�;2�#�;2���#�;2�#�;2�#�;��"�;2�#�;2�#�;2�#�;2�#�;2�#�;2�#�;2���#�;2�#�;2�#�;��J2�3��$�;�;�;Ҽ#�;Ҽ#�;��#�;��#�;��#�;���Ϸ=DpwwgtaZpwwGpwwG�v$oG�v$oG�v$oG�v$oG�v$oG�v$oG�v$oG�v$oG#sG�v$ogt�H�v$oG�v42w�qGw�qGw�qGw�qGw�qGw�qGw�qG�v$oG�v$oG�v$o窇Hގ��Hގ��Hގ�8��8��8�H����ɑ���=[~��;�>�~��=���M
#�;"�#�;"�#�;��;W�E�w�~G�w�.*�������r�W����^��+�{�~�����r�W����^��+�{E|����"�W����^�+�{E|����"�W��J�^i�+�{�y�4��ҼW��J�^i�+�{�y���^�+d{�l�<핧��W����^y�+O{�i�<핧��W����^y�+O{�i�<핧��W��.uy�+O{�i�<핧��W����^y�+O{5����^yڻ��^)�+%{�d���]4��앒�R�WJ�J�^)�+{b��)ƕ}���W��j>�}a��}�x�~pߎ�֧�>�9?��?'8�Oq��;�gE?>��)�㯯�,��Nt0��+�{w����p�+�{5\�
�^׽��Wp�
�^��+�{w�V۸Ttw���ܽ��Wp�
�^��+�{w���ܽ��Wp�
�ލ�Wp�
�^��+�{w���ܽ��Wp�j��ܽ��Ww���ܽ��Wp�~���]B����+�{w���ܽ��Wp�j���ҼW��J�^��+�{w�����+�{w���ܽ��Wp�
�^��+�{w���ܽ��W��J�^��+y{%o���=^��핼���W��J�^��+y{%o��핼���W��}�%o��핼���W��J���Ś���W��������������_�!�|�=z����G����ޤ���ҼW����^q�+�{�q�8�ǽ���~8.���[�. ]q�+�{�qo�C�������x��ǽ�W���^q�+�{�q��>7�y��ǽ�W���^q�+�{�n �����sE�W�J�^��+y{%o��핼���W��J�^�۫��W����ޏ�}���!�W����^y�+O{�i�<핧��7��+O{�i�<핧��W��~<-�Zz�<핧��W����^y�+O{�i�<핧��W���z�<핧��W������sWo���>��[��.������W�m�<핧��W����^)�+%{�d��앒�R�71��5q��b(ċ�問[n�G�����ŏ?x�q�8��t�+�{�q�8�ǽ�W�j:�ǽ�s.q�+�{??��<�W���^q�+�{�qo�Y�xJ<�q�+�{[ͪլZ�J���^q�+�{�q�8�ǽ�W�jd�ǽ�W���^q�+�{�q�8�ǽ��"�{�q�����B�W��
�^!�+d{?�E��hB�W���څ<핧��AV�<핧��� O{[����i�<��x�+:{5����^��+%{�d��앒��y{Eg�������Wt���^�٫��Wt���^�٫��Wt���^��;JNDg���������=?w�?�s�)>�z��^q�+�{�q�8�ǽ�W���^q�+�{�q�8�ǽ�W�p�8�ǽ�W���ޫ�q�+�{�q�8�ǽ�W���^q�+�{�q���ޫ�͂�Wp�
�^��+�{w�F�^��+�{w���ܽ��Wp�>A��V�&�{E|���:����r�W����^q�+��.jE�62�Wcx�sZ��>#tݫټWF��讗<�������M�T�ʧ��u?����>ޘw��a>��[�rm�&�rm�c�O�k{6�O�k{��w��k>U���m>U���o>U���q>U���s>U���u>U���w>U���y>�G��T���Χ�89�T��g��T��g�T��g�T������S}��O��۳���N��rm�^��rm�F���*~�h�wG8�S�'/��>��yWՍ$�?U�M�HH�S�^�؍��?U�M�H~�S��ԍD�?U�M�H��S�m�YR�8E�gXL�&k�K/��_��G����x�2�Z�Mi�"�J#-��nJ#����)��@oP�)��>J7��
�A�6�v�E���nJ#U���Mi��oNj��v�����\W�7(���b���n�(����M�"pP�)���T�6pP�)�T�㦌R'8(ݔQ���2J��tSF��n�(��7UF�!�n�(����)��J7e���A馌R[8(�����1���>Si8(��j�A���&z�Y5(ݔQj��2J��tk�GT9(��2J%�tSF���n�(U�7UFi�tSF���BsP�)�����(����M�bsP7e���A馌R�9(ݔQj8��:�A�]���z��gZb8(����AqG-Z�n�(u���M�Q��zsP��>J�tSFi��tSF���n�(U�7UFi��tSFi��<n�(U���M�g|�2J��tSF���n�(����M�����M�%�sR	:(��U��z��g�G�>SA:(��*�A�֎UP�3դ��\��Q�O��2J�tSF�D�n�(����M���7UF�L�n�(����)�T�J7e�Z�A馌R�:(ݔQ�V�ߣԮJ7e�,J7e�:�9�d��
�A�wԩ�#�U�7U�B��U�E�#S��H���DU���D%����-;�n�U���B��bsP����Ai���bÛ*5�oJ7����Ai�{���B��%���B��U�sR�9(�����z��g*7�>S�9(~�R�9(ݔ%�8���a�aT~J7���A��Q:(ݔ;Z�8(ݔ;Z�8f���6o���o\����:^;�ߦ<ӊ�A�ϔr�c����L9-|��RN��tS�i��<�}jl���O���tS�i�pSs;(�����z��g�t�>S�;(�Oe�tS����n�;��?�
J7e����*�TJ7e���A��S%<(ݔ}j���2J��tSF���n�(U�7UF���n�(����)�T�J7e�Z�A馌R�;(�T���j���vG'��>Ni��h�W�w����\�6��Ա��fǂk���{��פ��p=�q(����\ ���%�����"t�����������{���ˋ�C�o�/Î��ˡ���ô����r�c���G����Sp�y�}x_^?醟}���M�H߹F�c'����9��5��o��n����<7y;����/�E�R��>d>n(�f���o4��T�w��w��L��P�����d�9z��*��4�^W�������M��y�{(�n��N�ϔ���qn�u�>y�<>��/�o?>��Q���d��>ڿX��:c��9s&u��G*i^�*X m  ��:� �`,'A�d�d�d�d�d�d�d	e�h�E�/|���_4���W��pT�Y2�2�2�2�2�2�2j2j2j2j�Xd�d�n��\�4�4�4�4/i^Ҽ�yI�b(H��%�KF������������:sNF]F]F]FCFCFCFCFCFCF��-�!�!�)�)�)�)�)�)�)���HFSFKFKFKFKFKF�q!�%��	�3,���96q�M�e���y6q�M�i��D��u��Z�*X��:� �`l��P&Y*Y.Y2Y6Y:Y>YBYFEFE�/|���_4����h�U��:�g��������������������/55555]2�dt�����_F��.]2�d�e�e�e�e�e�i2�2�2�2222222LiMMMMMMMMN<2�2Z2Z2Z2Z2Z2Z2Z2Z2Z�K=�r6M�N���	5qFM�R���I5qVMt�Zǃ�V�����[`���2�R�rɒɲ������2*2*|���_4����h�E��|��<�dTeTeTeTeTeTe�d�d�d�x�Ȩɨɨɨɨ���%�KF��.^�2�dt���%�.�.�.�.�.��H�Q�Q�Q�ѐѐѐѐѐѐ�`J�h�h�h�h�h�h�h�h�h�hr�єђђђђђђђђ��\�ɔ�i�t�8�&N��3j┚8�&N���j��Z���_��ɲ~G���=��/��9?>�V��������Z./�����|�3��[��7������1��X�0��V��9�y�Lr޳ű�+����gM�{!`<��wfz�>����b}��=�;�q���n~z��o+��>v�������������ly��->�َ'�E�q/<���^��������p+"     