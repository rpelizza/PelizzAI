# Refactoring Candidates

After the TDD cycle, look for:

- **Duplication** → Extract a function/class
- **Long methods** → Split into private helper methods (keep the tests on the public interface)
- **Shallow modules** → Combine or deepen
- **Feature envy** → Move the logic to where the data lives
- **Primitive obsession** → Introduce _value objects_
- **Existing code** that the new code reveals to be problematic
