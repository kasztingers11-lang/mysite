# Supplied screenshots

All four screenshots available in the conversation workspace are included below unchanged. These are reference examples, not proof that the current runtime implements them.

## 1. Endmath feature description

![Endmath feature description](../images/image(20261021-182726).png)

Describes trajectory modification, vertical control, jumping/falling offsets, velocity history and a preview. It does not supply an implementation or prove compatibility with the target games.

## 2. 3d-Angles example

![3d-Angles distance example](../images/image(20261021-182814).png)

The example describes a maximum distance between mouse and target position, with a value of 2.2. It does not describe the adjustable degree limits used in the previous implementation. Confirm coordinate space and units before coding a replacement.

## 3. Endmath settings example

![Endmath radius and wall check settings](../images/image(20261021-182848).png)

Shows Velocity History, WallCheck and an Anti Curve radius around the mouse. A radius of 120 is shown. Whether this is screen or world space must be established from actual implementation; do not silently interpret it as a 120-stud prediction cap.

## 4. Client bullet redirection example

![Client bullet redirection settings](../images/image(20261021-182940).png)

Shows enabled redirection, allowed guns and a target restriction. The user's later requirement simplifies the exposed neoperro configuration to Enabled, with a valid target always required internally.
