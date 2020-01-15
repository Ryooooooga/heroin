const app = new Vue({
  el: "#main",
  data: {
    posts: null
  },
  template: `
    <div>
      <h2>Posts</h2>
      <form action="/posts" method="post">
        <div>
          <input name="author" type="text">
        </div>
        <div>
          <textarea name="text"></textarea>
        </div>
        <div>
          <button type="submit">Send</button>
        </div>
      </form>
      <p v-if="posts === null">Loading...</p>
      <ul v-else>
        <li v-for="post in posts">
          {{post.id}}: {{post.text}} by {{post.author}}
        </li>
      </ul>
    </div>
    `,
  async mounted() {
    const res = await fetch("/posts");
    const posts = await res.json();
    this.posts = posts;
  }
});
