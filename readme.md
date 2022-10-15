## Projet - Système de vote
----------------------------------------------------------------
Note :
Pour cet exercice, j'ai essayé de rester le plus simple possible.
J'y ai apporté quelques améliorations, mais sans alourdir le contrat.
( gestion égalité, reset du vote, tableau de data des votes, override de renounceOwnership )
----------------------------------------------------------------
Le processus de vote :

•	L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    ↳```function setWhitelist()```
            ↳ Cette fonction attend une liste d'adresses Ethereum en paramètre.


•	L'administrateur du vote commence la session d'enregistrement de la proposition.
    ↳```function ProposalsRegistrationStarted()```


•	Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
    ↳```function recordProposalsRegistration()```
            ↳ Cette fonction attend une chaine de caractere en parametre qui fait office de proposition. 
            ↳ J'ai interprété la consigne comme chaque électeur ne peut envoyer qu'une seule proposition pas session de vote. Mais chaque électeur peut envoyer sa proposition.


•	L'administrateur de vote met fin à la session d'enregistrement des propositions.
    ↳```function ProposalsRegistrationEnded()```


•	L'administrateur du vote commence la session de vote.
    ↳```function VotingSessionStarted()```


•	Les électeurs inscrits votent pour leur proposition préférée.
    ↳```function recordVotingSession()```
            ↳ Cette fonction attend un uint représentant ID de la proposition.


•	L'administrateur du vote met fin à la session de vote.
    ↳```function VotingSessionEnded()```


•	L'administrateur du vote comptabilise les votes.
    ↳```function VotesTallied()```
            ↳ Dans cette fonction j'ai ajouter le cas d'égalité potentiel dans ce cas le vote est considéré comme null.


•	Tout le monde peut vérifier les derniers détails de la proposition gagnante.
    ↳```function getWinner()```


•	L'administrateur du vote supprime la liste blanche, le tableau des propositions et le potentiel tableau des égalites, en vue d'un prochain vote.
    ↳```function resetDataVoting()```
            ↳ Cette fonction attend la liste d'adresses Ethereum de la white list en paramètre.


•	Tous les participants peuvent vérifier les données du vote (quelle adresse à voter pour quelle proposition).
    ↳```function getVoteData()```


•	Tous les participants peuvent vérifier le tableau des ID des propositions arrivé à égalité.
    ↳```function getEquality()```



•	Petit override de la fonction hérité de Ownable pour éviter les accidents.
    ↳```renounceOwnership()```

