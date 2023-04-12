# dsp-schemas

### Message schema evolution

┌─Producer-A─────────────────────────┐                                                              ┌─Consumer-A─────────────────────────┐
│                                    │                                                              │                                    │
│   Coded/tested schema:v1 (old)     │          ┌─Persistent-Message-Topic───────────┐              │  Coded/tested  schema:v1 (old)     │
│                                    │  still   │                                    │              │  Receives schema:v2 (current)      │
│  ┌─Schema-v1────────────────────┐  │ accepted?│       Registered schema:v2         │ can          │ ┌─Schema-v2────────────────────┐   │
│  │{name:str}                    │  ├─────────►│                                    │ handle?      │ │{name: str}                   │   │
│  └──────────────────────────────┘  │          │  ┌─Schema-v1────────────────────┐  ├─────────────►│ └──────────────────────────────┘   │
│                                    │          │  │{name:str}                    │  │              │                                    │
└────────────────────────────────────┘          │  └──────────────────────────────┘  │              └────────────────────────────────────┘
                                                │                                    │
┌─Producer-B─────────────────────────┐          │  ┌─Schema-v2────────────────────┐  │ can          ┌─Consumer-B─────────────────────────┐
│                                    │ schema   │  │{name:str,pet:dog|cat}        │  │ handle?      │                                    │
│   Coded/tested schema:v2 (current) │ match!   │  └──────────────────────────────┘  ├─────────────►│  Coded/tested  schema:v2 (current) │
│                                    ├─────────►│                                    │              │  Receives schema:v1 (old)          │
│ ┌─Schema-v2────────────────────┐   │          └────────────────────────────────────┘              │ ┌─Schema-v1────────────────────┐   │
│ │{name:str,pet:dog|cat}        │   │                 ▲                                            │ │{name:str,pet:dog|cat}        │   │
│ └──────────────────────────────┘   │                 │                                            │ └──────────────────────────────┘   │
│                                    │                 │                                            │                                    │
└────────────────────────────────────┘                 │                                            └────────────────────────────────────┘
                                                       │
┌─Producer-C─────────────────────────┐                 │
│                                    │ already         │
│   Coded/tested schema:v3 (new)     │ accepted?       │
│                                    ├─────────────────┘
│ ┌─Schema-v3────────────────────┐   │
│ │{name:str,pet:dog|cat|hen}    │   │
│ └──────────────────────────────┘   │
│                                    │
└────────────────────────────────────┘

### helpful links

Schema evolution strategies:
  - https://developer.confluent.io/learn-kafka/schema-registry/schema-compatibility/
  - https://medium.com/storyblocks-engineering/foolproof-schema-management-with-github-actions-and-avro-afb0ebb00dfe
  - https://medium.com/expedia-group-tech/practical-schema-evolution-with-avro-c07af8ba1725
  - https://docs.github.com/en/actions/publishing-packages/publishing-java-packages-with-maven

  - https://tkaszuba.medium.com/avro-schema-evolution-strategies-on-kafka-3c072a9a5347
  - https://medium.com/flippengineering/schema-and-topic-design-in-event-driven-systems-featuring-kafka-a555ddfdb8d8

Naming strategies:
  - https://www.confluent.io/blog/multiple-event-types-in-the-same-kafka-topic/
  - https://www.confluent.io/blog/put-several-event-types-kafka-topic/
  - https://developer.confluent.io/learn-kafka/schema-registry/schema-subjects/
  - https://docs.confluent.io/5.3.1/schema-registry/serializer-formatter.html#how-the-naming-strategies-work

