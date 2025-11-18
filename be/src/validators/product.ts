import Joi from 'joi';

const productSizeSchema = Joi.object({
  size: Joi.string().required().min(1).max(20),
  price: Joi.number().positive().required()
});

export const productSchema = Joi.object({
  name: Joi.string().required().min(1).max(200),
  description: Joi.string().optional().allow('').max(1000),
  img: Joi.string().required().uri(),
  categoryId: Joi.number().integer().positive().required(),
  sizes: Joi.array().items(productSizeSchema).min(1).required()
});

export const validateProduct = (data: any) => {
  return productSchema.validate(data, { abortEarly: false });
};