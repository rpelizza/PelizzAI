# Candidatos à Refatoração

Após o ciclo de TDD, busque por:

- **Duplicação** → Extrair função/classe
- **Métodos longos** → Dividir em métodos auxiliares privados (mantenha os testes na interface pública)
- **Módulos superficiais** → Combinar ou aprofundar
- **Inveja de funcionalidade** → Mover a lógica para onde os dados residem
- **Obsessão por primitivos** → Introduzir objetos de valor (_value objects_)
- **Código existente** que o novo código revela ser problemático
