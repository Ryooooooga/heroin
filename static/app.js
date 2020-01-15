const app = new Vue({
  el: "#main",
  data: {
    posts: null,
    author: "",
    text: ""
  },
  methods: {
    async submit() {
      const res = await fetch("/posts", {
        hreaders: {
          "Content-Type": "application/json; charset=utf-8"
        },
        method: "POST",
        body: JSON.stringify({
          author: this.author,
          text: this.text
        })
      });
      const posts = await res.json();
      this.posts = posts;
    }
  },
  template: `
    <div>
      <h2>Posts</h2>
      <form @submit.prevent="submit">
        <div>
          <input name="author" type="text" v-model="author">
        </div>
        <div>
          <textarea name="text" v-model="text"></textarea>
        </div>
        <div>
          <button type="submit">Send</button>
        </div>
      </form>
      <p v-if="posts === null">Loading...</p>
      <ul v-else>
        <li v-for="post in posts">
          {{post.id}}: {{post.text}} by {{post.author}} at {{post.createdAt}}
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
