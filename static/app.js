const store = {
  posts: null
};

const Title = {
  template: `
    <h1>Sample Application</h1>
  `
};

const Form = {
  data: () => ({
    author: "noname",
    text: ""
  }),
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

      if (res.ok) {
        this.text = "";
        store.posts = await res.json();
      }
    }
  },
  template: `
    <div>
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
    </div>
  `
};

const Loading = {
  template: `
    <p>Loading...</p>
  `
};

const Posts = {
  props: {
    posts: Array
  },
  template: `
    <ul>
      <li v-for="post in posts">
        <p>{{post.id}}: {{post.author}} at {{post.createdAt}}</p>
        <p v-html="post.htmlText"></p>
      </li>
    </ul>
  `
};

const app = new Vue({
  el: "#main",
  components: {
    Title,
    Form,
    Loading,
    Posts
  },
  data: store,
  computed: {
    isLoading() {
      return this.posts === null;
    }
  },
  template: `
    <main>
      <Title />
      <Form />
      <Loading v-if="isLoading" />
      <Posts v-else :posts="posts" />
    </main>
  `,
  async mounted() {
    const res = await fetch("/posts");
    if (res.ok) {
      const posts = await res.json();
      this.posts = posts;
    }
  }
});
