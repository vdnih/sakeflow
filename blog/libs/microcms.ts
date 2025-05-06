import { createClient } from 'microcms-js-sdk';
import type {
  MicroCMSQueries,
  MicroCMSImage,
  MicroCMSDate,
  MicroCMSContentId,
} from 'microcms-js-sdk';
import { notFound } from 'next/navigation';

// カテゴリの型定義
export type Category = {
  name: string;
  value: string;
} & MicroCMSContentId & MicroCMSDate;

// ライターの型定義
export type Writer = {
  name: string;
  profile: string;
  image?: MicroCMSImage;
} & MicroCMSContentId &
  MicroCMSDate;

// ブログの型定義
export type Blog = {
  title: string;
  content: string;
  thumbnail?: MicroCMSImage;
  category: Category;
  writer: Writer;
  description: string;
};

export type Article = Blog & MicroCMSContentId & MicroCMSDate;

if (!process.env.MICROCMS_SERVICE_DOMAIN) {
  throw new Error('MICROCMS_SERVICE_DOMAIN is required');
}

if (!process.env.MICROCMS_API_KEY) {
  throw new Error('MICROCMS_API_KEY is required');
}

// Initialize Client SDK.
export const client = createClient({
  serviceDomain: process.env.MICROCMS_SERVICE_DOMAIN,
  apiKey: process.env.MICROCMS_API_KEY,
});

// ブログ一覧を取得
export const getList = async (queries?: MicroCMSQueries) => {
  try {
    const listData = await client.getList<Blog>({
      endpoint: 'blogs',
      queries,
    });
    return listData;
  } catch (error) {
    console.error('Failed to fetch blog list:', error);
    throw error;
  }
};

// ブログの詳細を取得
export const getDetail = async (contentId: string, queries?: MicroCMSQueries) => {
  try {
    const detailData = await client.getListDetail<Blog>({
      endpoint: 'blogs',
      contentId,
      queries,
    });
    return detailData;
  } catch (error) {
    console.error('Failed to fetch blog detail:', error);
    throw error;
  }
};

// カテゴリ一覧を取得
export const getCategoryList = async () => {
  try {
    const listData = await client.getList<Category>({
      endpoint: 'categories',
    });
    return listData;
  } catch (error) {
    console.error('Failed to fetch category list:', error);
    throw error;
  }
};

// カテゴリの詳細を取得
export const getCategory = async (categoryId: string) => {
  try {
    const categoryData = await client.get({
      endpoint: 'categories',
      contentId: categoryId,
    });
    return categoryData;
  } catch (error) {
    console.error('Failed to fetch category:', error);
    throw error;
  }
};