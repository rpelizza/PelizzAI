# Testes Bons e Ruins

## Bons Testes

**Estilo de integração**: Teste através de interfaces reais, não de mocks de partes internas.

```typescript
// BOM: Testa o comportamento observável
test('usuário finaliza a compra com um carrinho válido', async () => {
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
test('checkout chama paymentService.process', async () => {
	const processSpy = jest.spyOn(paymentService, 'process');
	await checkout(cart);
	expect(processSpy).toHaveBeenCalledWith(cart.total);
});
```

Sinais de alerta:

- Mockar colaboradores internos
- Testar métodos privados
- Verificar contagens/ordem de chamadas
- O teste quebra ao refatorar sem mudança de comportamento
- O nome do teste descreve COMO, não O QUE
- Verificação por meios externos em vez da interface

```typescript
// RUIM: Ignora a interface para verificar
test('createUser grava no banco de dados', async () => {
	await createUser({ name: 'Alice' });
	const row = await db.query('SELECT * FROM users WHERE name = ?', ['Alice']);
	expect(row).toBeDefined();
});

// BOM: Verifica por meio da interface
test('createUser torna o usuário recuperável', async () => {
	const user = await createUser({ name: 'Alice' });
	const retrieved = await getUser(user.id);
	expect(retrieved.name).toBe('Alice');
});
```
