export interface AsyncCallback<T, E = void> {
  /**
   * Defines the callback data.
   * @since 6
   */
  (err: BusinessError<E>, data: T): void;
}

export interface BusinessError<T = void> extends Error {
  /**
   * Defines the basic error code.
   * @since 6
   */
  code: number;
  /**
   * Defines the additional information for business
   * @type { ?T }
   * @since 9
   */
  data?: T;
}