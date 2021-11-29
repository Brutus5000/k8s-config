# FAF Backend Architecture

FAF is a complex landscape. We try to draw the complete picture here.

**Legend**

![Legend](https://g.gravizo.com/source/legend_mark?https%3A%2F%2Fraw.githubusercontent.com%2FBrutus5000%2Fk8s-config%2Fgraphviz%2FARCHITECTURE.md)
<details><summary></summary>
legend_mark
digraph Legend {
    infrastructure [style=filled, color=green]
    monitoring [style=filled, color=cadetblue1]
    forum [style=filled, color=yellow]
    "faf-core" [style=filled, color=red]
    "faf-extra" [style=filled, color=pink]
    chat [style=filled, color=aquamarine]

}
legend_mark
</details>

**Service Overview**

![Service Overview](https://g.gravizo.com/source/service_overview_mark?https%3A%2F%2Fraw.githubusercontent.com%2FBrutus5000%2Fk8s-config%2Fmain%2FARCHITECTURE.md)
<details><summary></summary>
service_overview_mark
digraph FAF {
    subgraph infrastructure {
        node [style=filled, color=green];
        MongoDB
        MariaDB
        RabbitMQ
        "Ory Hydra" [tooltip = "OAuth2 server"]
        Traefik
        Coturn
        Postal [tooltip = "Mail server"]
    }

    subgraph monitoring {
        node [style=filled, color=cadetblue1];
        Grafana -> Prometheus
        "MySQL-Exporter",
        "Node-Exporter",
        Cadvisor
    }

    subgraph forum {
		node [style=filled, color=yellow];
        NodeBB -> MongoDB [ label = "db=nodebb" ]
        "phpBB3 Archive"
    }

    subgraph "faf-core" {
		node [style=filled, color=red];
		"User Service"
        API
        "Lobby Server"
        "Replay Server"
        "League Service"
        Website -> "Lobby Server" [ label = "game stats" ]
        Wordpress
        "Content Server"
        Mautic
        QAI
        UnitDB

        "Lobby Server" -> API [ label = "achievement updates" ]
        Website -> API [ label = "leaderboards" ]
        Website -> API [ label = "registration,\npw-reset" ]
        Website -> Wordpress [ label = "news" ]
    }

    subgraph "faf-extra" {
		node [style=filled, color=pink];
        MediaWiki
        Voting
    }


    subgraph "chat" {
		node [style=filled, color=aquamarine];
        UnrealIRCD -> Anope [ label = "IRC services" ]
    }

    "Ory Hydra" -> "User Service" [label = "authentication"]

    NodeBB -> API [ label = "user lookup"]
    API -> NodeBB [ label = "sync account change"]

    "User Service" -> MariaDB [ label ="db=faf" ]
    API -> MariaDB [ label ="db=faf,league-service" ]
    API -> MariaDB [ label ="db=league-service" ]
    API -> MariaDB [ label ="db=anope" ]
    "Lobby Server" -> MariaDB [ label ="db=faf" ]
    "Lobby Server" -> MariaDB [ label ="db=anope" ]
    "Replay Server" -> MariaDB [ label ="db=faf" ]
    "League Service" -> MariaDB [ label="db=league-service"]
    Wordpress -> MariaDB [ label="db=wordpress" ]
    Anope -> MariaDB [ label = "db=anope"]
    MediaWiki -> MariaDB [ label = "db=mediawiki" ]
    "MySQL-Exporter" -> MariaDB [ label = "metrics" ]
    "Lobby Server" -> RabbitMQ [ label = "game events"]
    "League Service" -> RabbitMQ [ label = "game events" ]
    "Lobby Server" -> Coturn [ label = "directs games to" ]
    API -> Mautic [ label="manage contacts,\nsend emails"]
    NodeBB -> Postal
    Mautic -> Postal
    MediaWiki -> Postal
    QAI -> UnrealIRCD
    QAI -> API [ label = "data lookup" ]
    Voting -> API [ label = "frontend for voting" ]


    Traefik -> {
        API,
        Website,
        "User Service",
        "Ory Hydra",
        "Content Server",
        Wordpress,
        "phpBB3 Archive",
        Voting,
        MediaWiki,
        UnitDB
        Prometheus
        Grafana
    }
    Traefik -> RabbitMQ [ label = "only Dashboard" ]

    Prometheus -> {
        Traefik,
        API,
        "Lobby Server",
        "Replay Server",
        "MySQL-Exporter",
        "Node-Exporter",
        Cadvisor
        RabbitMQ
    }
}
service_overview_mark
</details>

Some edges are unnamed to avoid repetition:

* Traefik serves all references services as reverse proxy
* Prometheus scrapes referenced other services for metrics
* Postal sends emails for all referenced services