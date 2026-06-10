### Never Assume Message Order From Queues

NEVER write a queue consumer that depends on messages arriving in the order they were produced. Competing consumers, retries, redeliveries, and multi-partition brokers all reorder messages, so a consumer that assumes sequence will corrupt state in production.

- Make each message self-sufficient: include the entity ID and either a version number, sequence number, or authoritative timestamp from the producer, so the consumer can decide what to do without trusting arrival order.
- Use last-write-wins guarded by version: reject or ignore a message whose version/sequence is older than what is already stored (`UPDATE ... WHERE version < :incoming`). Never blindly apply the latest arrival.
- For genuine state machines, treat out-of-order arrivals as expected input: either park the early message for redelivery, or store it and reconcile when the missing predecessor arrives. Do not throw on "impossible" transitions.
- If strict ordering is truly required, get it from the broker explicitly (FIFO queue with message group ID, Kafka partition keyed by entity ID, single consumer per key) and say so in a comment. Do not get it implicitly from "there's only one consumer right now."
- Remember that redelivery reorders even single-consumer setups: a nacked message goes to the back of the line while newer messages sail past it.

**Red flags that you're about to violate this:**
- "Events are published in order, so they arrive in order."
- "There's only one consumer, so ordering is guaranteed."
- "The paid event always comes after the created event."
- "I'll throw an exception if the state transition is invalid — it can't happen."
- "Kafka is ordered." (Only per partition, only with the right key.)
- "Handling out-of-order events makes the consumer too complicated."
