export function EmptyState({ title, message }: { title: string; message: string }) {
  return (
    <section className="empty-state">
      <div className="empty-icon">⌁</div>
      <h2>{title}</h2>
      <p>{message}</p>
    </section>
  )
}
