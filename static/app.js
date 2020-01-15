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
    <div class="form">
      <form @submit.prevent="submit">
        <label class="form__label">Name</label>
        <input class="form__input" name="author" type="text" v-model="author">
        <label class="form__label">Text</label>
        <textarea class="form__textarea" name="text" v-model="text"></textarea>
        <button class="form__submit" type="submit">Send</button>
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
    <div>
      <section class="post" v-for="post in posts">
        <div class="post__header">
          <span class="post__id">{{post.id}}</span>:
          <span class="post__author">{{post.author}}</span>
        </div>
        <div class="post__body" v-html="post.htmlText"></div>
        <div class="post__footer">
          <span class="post__timestamp">{{new Date(post.createdAt).toLocaleString()}}</span>
        </div>
      </section>
    </div>
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
