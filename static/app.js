const isDebug = location.hostname === "localhost";

const debug = isDebug ? console.log : () => {};

// Store
const store = {
  posts: null
};

// Mutations
const mutation_types = Object.freeze({
  POST_FETCHED: "POST_FETCHED"
});

const mutations = Object.freeze({
  [mutation_types.POST_FETCHED]({ posts }) {
    store.posts = posts;
  }
});

const emit = (type, param) => {
  debug(`emit(${type})`, param);
  mutations[type](param);
};

// Actions
const action_types = Object.freeze({
  FETCH_POST: "FETCH_POST",
  CREATE_POST: "CREATE_POST"
});

const actions = Object.freeze({
  async [action_types.FETCH_POST]() {
    const res = await fetch("/posts");

    if (res.ok) {
      const posts = await res.json();
      emit(mutation_types.POST_FETCHED, { posts });
    } else {
    }
  },
  async [action_types.CREATE_POST]({ author, text }) {
    const res = await fetch("/posts", {
      hreaders: {
        "Content-Type": "application/json; charset=utf-8"
      },
      method: "POST",
      body: JSON.stringify({ author, text })
    });

    if (res.ok) {
      const posts = await res.json();
      emit(mutation_types.POST_FETCHED, { posts });
    } else {
    }
  }
});

const dispatch = async (type, param) => {
  debug(`dispatch(${type})`, param);
  await actions[type](param);
};

// Components
const Title = {
  template: `
    <h1>Sample Application</h1>
  `
};

const Form = {
  props: {
    id: { type: String, required: true }
  },
  data: () => ({
    author: "noname",
    text: ""
  }),
  computed: {
    author_id() {
      return `${this.id}__author`;
    },
    text_id() {
      return `${this.id}__text`;
    }
  },
  methods: {
    async onSubmit() {
      await dispatch(action_types.CREATE_POST, {
        author: this.author,
        text: this.text
      });

      this.text = "";
    }
  },
  template: `
    <div class="form">
      <form :id="id" @submit.prevent="onSubmit">
        <label class="form__label" :for="author_id">Name</label>
        <input :id="author_id" class="form__input" name="author" type="text" v-model="author">
        <label class="form__label" :for="text_id">Text</label>
        <textarea :id="text_id" class="form__textarea" name="text" v-model="text"></textarea>
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

const Post = {
  props: {
    post: { type: Object, required: true }
  },
  computed: {
    timestamp() {
      return new Date(this.post.createdAt).toLocaleString();
    }
  },
  template: `
    <section class="post">
      <div class="post__header">
        <span class="post__id">{{post.id}}</span>:
        <span class="post__author">{{post.author}}</span>
      </div>
      <div class="post__body" v-html="post.htmlText"></div>
      <div class="post__footer">
        <span class="post__timestamp">{{timestamp}}</span>
      </div>
    </section>
  `
};

const Posts = {
  props: {
    posts: { type: Array, required: true }
  },
  components: {
    Post
  },
  template: `
    <div>
      <Post v-for="post in posts" :key="post.id" :post="post" />
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
      <Form id="form" />
      <Loading v-if="isLoading" />
      <Posts v-else :posts="posts" />
    </main>
  `,
  async mounted() {
    await dispatch(action_types.FETCH_POST);
  }
});
