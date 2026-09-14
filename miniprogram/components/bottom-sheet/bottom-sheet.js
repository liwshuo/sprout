// components/bottom-sheet/bottom-sheet.js
Component({
  properties: {
    show: { type: Boolean, value: false },
    title: { type: String, value: '' },
    cancelText: { type: String, value: '取消' },
    confirmText: { type: String, value: '确定' },
    confirmDisabled: { type: Boolean, value: false },
    hideCancel: { type: Boolean, value: false },
    maskClosable: { type: Boolean, value: true },
  },
  methods: {
    _onMaskTap() {
      if (!this.data.maskClosable) return;
      this.triggerEvent('cancel');
    },
    _onCancel() {
      this.triggerEvent('cancel');
    },
    _onConfirm() {
      if (this.data.confirmDisabled) return;
      this.triggerEvent('confirm');
    },
    _catchStop() {
      // 阻止 catchtap 事件冒泡
    },
  },
});
