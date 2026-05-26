export function run(user: { id: string }) {
  console.log(user.id)
  console.error("failed", user.id)
}
