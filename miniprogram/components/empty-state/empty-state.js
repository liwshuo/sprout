// components/empty-state/empty-state.js
Component({
  properties: {
    icon: { type: String, value: '🌱' },
    title: { type: String, value: '还没有内容' },
    subtitle: { type: String, value: '' },
    actionText: { type: String, value: '' },
  },
  methods: {
    _onAction() {
      this.triggerEvent('action');
    },
  },
});
