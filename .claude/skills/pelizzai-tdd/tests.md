# Testes Bons e Ruins

## Bons Testes

**Estilo de integração**: Teste através de interfaces reais, não de mocks de partes internas.

```typescript
// BOM: Testa o comportamento observável
test('user can checkout with valid cart', async () => {
	const cart = createCart();
	cart.add(product);
	const result = await checkout(cart, paymentMethod);
	expect(result.status).toBe('confirmed');
});
```

Características:

- Testa comportamentos relevantes para usuários/chamadores
- Utiliza apenas a API pública
- Resiste a refatorações internas
- Descreve O QUE, não COMO
- Uma asserção lógica por teste

## Testes Ruins

**Testes de detalhes de implementação**: Acoplados à estrutura interna.

```typescript
// RUIM: Testa detalhes de implementação
test('checkout calls paymentService.process', async () => {
	const mockPayment = jest.mock(paymentService);
	await checkout(cart, payment);
	expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mockando colaboradores internos
- Testando métodos privados
- Afirmação de contagens/pedidos de chamadas
- Teste quebra ao refatorar sem mudança de comportamento
- O nome do teste descreve COMO e não O QUE
- Verificação através de meios externos em vez de interface

```typescript
// RUIM: Ignora a interface para verificar
test('createUser saves to database', async () => {
	await createUser({ name: 'Alice' });
	const row = await db.query('SELECT * FROM users WHERE name = ?', ['Alice']);
	expect(row).toBeDefined();
});

// BOM: Verifica por meio da interface
test('createUser makes user retrievable', async () => {
	const user = await createUser({ name: 'Alice' });
	const retrieved = await getUser(user.id);
	expect(retrieved.name).toBe('Alice');
});
```
